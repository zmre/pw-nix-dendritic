{inputs, ...}: {
  flake.nixosModules.llamacpp-qwen36 = {
    pkgs,
    config,
    ...
  }: let
    inherit (config.hardware) gpu;
    # GPU backend, chosen by benchmarking on avalon (see llamacpp-packages.nix
    # for numbers -- Vulkan won pp and tg on Qwen3.6-27B, 2026-07):
    #   "vulkan"     = pure Vulkan/RADV build (Hydra-cached, no local rebuild)
    #   "rocm-strix" = tuned ROCm build (rocWMMA flash-attn, gfx1151-only);
    #                  re-benchmark after nixpkgs bumps, the lead flips often
    backend = "vulkan";
    llamacppPkg =
      if gpu != "rocm"
      then pkgs.llama-cpp
      else if backend == "vulkan"
      then pkgs.llama-cpp-vulkan-strix
      else pkgs.llama-cpp-rocm-strix;
  in {
    environment.systemPackages = [llamacppPkg];
    services.llama-cpp = {
      enable = true;
      package = llamacppPkg;
      openFirewall = false;
      settings = {
        host = "127.0.0.1";
        model = "/var/lib/models/Qwen3.6-27B-Q4_K_M.gguf";
        port = 8081; # cuz glance is on 8080
        "verbose" = true;
        "log-file" = "/tmp/llama-server.log";
        "gpu-layers" = 999; # 999 = as many as possible
        "ctx-size" = 262144;
        "no-mmap" = true; # mmap'd pages kill ROCm perf on Strix Halo (2X+)
        "flash-attn" = "on"; # explicit; auto already enables it but be sure
        "batch-size" = 512;
        "ubatch-size" = 512;
        # Halve the 16 GiB KV cache at full context if memory gets tight:
        #"cache-type-k" = "q8_0";
        #"cache-type-v" = "q8_0";
        "presence-penalty" = 0.2;
        "n-predict" = 32768; # this is output-length
        "temp" = 0.6;
        "top-p" = 0.95;
        "top-k" = 20;
        "min-p" = 0.00;
      };
    };
    systemd.services.llama-cpp.environment =
      if backend == "vulkan"
      then {
        # RADV beats AMDVLK on Strix Halo, and AMDVLK's 2GB buffer limit
        # breaks 30B+ models
        AMD_VULKAN_ICD = "RADV";
      }
      else {
        # Dispatch rocBLAS GEMMs to hipBLASLt (gfx1151 kernels need ROCm 7.2+)
        ROCBLAS_USE_HIPBLASLT = "1";
        # Kernel 6.18 detects gfx1151 natively -- do NOT add
        # HSA_OVERRIDE_GFX_VERSION here. Trap: 6.19.x misdetects the GPU as
        # gfx1100 and needs HSA_OVERRIDE_GFX_VERSION=11.5.1 again.
      };
    networking.firewall.allowedTCPPorts = [8082];
    services.caddy.virtualHosts."${config.networking.hostName}.${config.networking.domain}:8082" = {
      listenAddresses = ["0.0.0.0"];
      extraConfig = ''
        tls {
          get_certificate tailscale
        }
        encode {
          zstd
          gzip
          minimum_length 1024
        }

        reverse_proxy http://127.0.0.1:8081 {
          header_up Host {upstream_hostport}
        }
      '';
    };
  };
}
