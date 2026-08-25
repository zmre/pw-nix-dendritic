{inputs, ...}: {
  flake.nixosModules.llamacpp-gemma = {
    pkgs,
    config,
    ...
  }: let
    inherit (config.hardware) gpu;
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
        port = 8081; # cuz glance is on 8080
        "verbose" = true;
        "log-file" = "/tmp/llama-server.log";
        models-preset = (pkgs.formats.ini {}).generate "models-preset.ini" {
          # note some other ways to specify models and names:
          #           hf-repo = "unsloth/Qwen3-Coder-Next-GGUF";
          #           hf-file = "Qwen3-Coder-Next-UD-Q4_K_XL.gguf";
          #           alias = "unsloth/Qwen3-Coder-Next";
          "gemma4-26b-a4b-q8" = {
            model = "/var/lib/models/gemma-4-26B-A4B-it-Q8_0.gguf";
            alias = "gemma4-26b-a4b-q8";
            "gpu-layers" = 999; # 999 = as many as possible
            "ctx-size" = 262144;
            "no-mmap" = true; # mmap'd pages kill ROCm perf on Strix Halo (2X+)
            "flash-attn" = "on"; # explicit; auto already enables it but be sure
            "batch-size" = 512;
            "ubatch-size" = 512;
          };
          "gemma4-26b-a4b-q4" = {
            hf-repo = "unsloth/gemma-4-26B-A4B-it-GGUF";
            hf-file = "gemma-4-26B-A4B-it-UD-Q4_K_M.gguf";
            "gpu-layers" = 999; # 999 = as many as possible
            "ctx-size" = 262144;
            "no-mmap" = true; # mmap'd pages kill ROCm perf on Strix Halo (2X+)
            "flash-attn" = "on"; # explicit; auto already enables it but be sure
            "batch-size" = 512;
            "ubatch-size" = 512;
          };
          "qwen36-27b-q4" = {
            model = "/var/lib/models/Qwen3.6-27B-Q4_K_M.gguf";
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
          "qwen38-27b-q8" = {
            hf-repo = "unsloth/Qwen3.8-27B-GGUF";
            hf-file = "Qwen3.8-27B-Q8_0.gguf";
            "gpu-layers" = 999; # 999 = as many as possible
            "ctx-size" = 262144;
            "no-mmap" = true; # mmap'd pages kill ROCm perf on Strix Halo (2X+)
            "flash-attn" = "on"; # explicit; auto already enables it but be sure
            "batch-size" = 512;
            "ubatch-size" = 512;
            # Halve the 16 GiB KV cache at full context if memory gets tight:
            #"cache-type-k" = "q8_0";
            #"cache-type-v" = "q8_0";
            "presence-penalty" = 0.0;
            "repetition-penalty" = 1.0;
            "n-predict" = 32768; # this is output-length
            "temp" = 1.0;
            "top-p" = 0.95;
            "top-k" = 20;
            "min-p" = 0.00;
          };
          "qwen38-27b-q4" = {
            hf-repo = "unsloth/Qwen3.8-27B-GGUF";
            hf-file = "Qwen3.8-27B-Q4_0.gguf";
            "gpu-layers" = 999; # 999 = as many as possible
            "ctx-size" = 262144;
            "no-mmap" = true; # mmap'd pages kill ROCm perf on Strix Halo (2X+)
            "flash-attn" = "on"; # explicit; auto already enables it but be sure
            "batch-size" = 512;
            "ubatch-size" = 512;
            # Halve the 16 GiB KV cache at full context if memory gets tight:
            #"cache-type-k" = "q8_0";
            #"cache-type-v" = "q8_0";
            "presence-penalty" = 0.0;
            "repetition-penalty" = 1.0;
            "n-predict" = 32768; # this is output-length
            "temp" = 1.0;
            "top-p" = 0.95;
            "top-k" = 20;
            "min-p" = 0.00;
          };
        };
        # Halve the 16 GiB KV cache at full context if memory gets tight:
        #"cache-type-k" = "q8_0";
        #"cache-type-v" = "q8_0";
        #"presence-penalty" = 0.2;
        #"n-predict" = 32768; # this is output-length
        #"temp" = 0.6;
        #"top-p" = 0.95;
        #"top-k" = 20;
        #"min-p" = 0.00;
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
