{
  flake.nixosModules.llamacpp-glm = {
    pkgs,
    config,
    lib,
    ...
  }: let
    llamacppPkg = pkgs.llama-cpp-vulkan;
  in {
    # GLM-4.7-Flash service (~10GB Q8_0 quant)
    # Efficient MoE, supports 200K context, starting with 128K

    environment.systemPackages = [
      llamacppPkg
    ];

    services.llama-cpp = {
      enable = true;
      package = llamacppPkg;
      host = "127.0.0.1";
      port = 8081;
      model = "/var/lib/models/GLM-4.7-Flash-Q8_0.gguf";
      extraFlags = [
        "--no-mmap" # CRITICAL for ROCm (2X+ perf)
        #"--mlock" # Keep in memory
        "--gpu-layers"
        "999" # All layers to GPU
        #"--threads"
        #"16" # CPU threads for non-GPU ops
        #"--threads-batch"
        #"16"
        #"--tensor-split"
        #"0" # No tensor splitting (single GPU)
        #"--temp"
        #"1.0"
        #"--min-p"
        #"0.0"
        #"--top-p"
        #"0.95"
        #"--top-k"
        #"64"
        #"--main-gpu"
        #"0"
        "--ctx-size"
        "0" # Whatever model says
        #"--batch-size"
        #"512"
        #"--ubatch-size"
        #"256"
        "--flash-attn" # Required for V cache quantization
        "on"
        #"--cache-type-k"
        #"q4_0"
        #"--cache-type-v"
        #"q4_0"
        "--jinja"
        "--verbose"
        "--log-file"
        "/tmp/llama-glm.log"
      ];
    };

    systemd.services.llama-cpp = {
      environment = {
        HSA_OVERRIDE_GFX_VERSION = "11.5.1"; # gfx1151 (Strix Halo) - use native version
        #ROCM_PATH = "${rocmPkg}";
        # LD_LIBRARY_PATH needed for stub loaders (libamd_comgr_loader.so -> libamd_comgr.so.3)
        #LD_LIBRARY_PATH = "${rocmPkg}/lib";
      };
      serviceConfig = {
        # Allow access to /proc/meminfo for UMA memory detection
        ProtectProc = lib.mkForce "default";
        ProcSubset = lib.mkForce "all";
      };
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
