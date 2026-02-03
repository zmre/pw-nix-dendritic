{inputs, ...}: {
  flake.nixosModules.llamacpp-gptoss = {
    pkgs,
    config,
    lib,
    ...
  }: {
    # GPT-OSS-120B service (~63GB MXFP4 quant)
    # MoE model requiring conservative batch sizes
    #
    #
    # toolbox enter llama-vulkan-amdvlk -- only thing that i got to work for this, but

    environment.systemPackages = [pkgs.stable.llama-cpp-vulkan];

    services.llama-cpp = {
      enable = true;
      package = pkgs.stable.llama-cpp-vulkan;
      host = "127.0.0.1";
      port = 5533;
      model = "/var/lib/models/ggml-org_gpt-oss-120b-GGUF_gpt-oss-120b-mxfp4-00001-of-00003.gguf";
      extraFlags = [
        "--no-mmap" # CRITICAL for ROCm (2X+ perf)
        #"--mlock" # Keep in memory
        "--gpu-layers"
        "999" # All layers to GPU
        #"--threads"
        #"16" # CPU threads for non-GPU ops
        #"--threads-batch"
        #"16"
        "--ctx-size"
        "0" # any size
        "--batch-size"
        "512" # Small batch for MoE stability
        "--ubatch-size"
        "512"
        "--flash-attn"
        "on"

        #--predict 256 (num tokens to predict, same as -n) batch-size 2048, ubatch-size 2048
        #llama-bench -m gpt-oss-20b-mxfp4.gguf -t 1 -fa 1 -b 2048 -ub 2048 -p 2048,8192,16384,32768

        #"--reasoning-format"
        #"none"

        #"--cache-type-k"
        #"q4_0"
        #"--cache-type-v"
        #"q4_0"
        #"--tensor-split"
        #"0" # No tensor splitting (single GPU)
        "--temp"
        "1.0"
        "--min-p"
        "0.0"
        "--top-p"
        "0.95"
        "--top-k"
        "20"
        "--main-gpu"
        "0"
        "--jinja"
        "--verbose"
        #"--log-file"
        #"/tmp/llama-gptoss.log"
      ];
    };

    systemd.services.llama-cpp = {
      environment = {
        #HSA_OVERRIDE_GFX_VERSION = "11.5.1"; # Required for gfx1151 (Strix Halo)
        HSA_OVERRIDE_GFX_VERSION = "11.5.1";
        HOME = "/var/lib/llama-cpp";
        XDG_CACHE_HOME = "/var/cache/llama-cpp";
        TMPDIR = "/run/llama-cpp";
      };

      # after = [
      #   "network.target"
      #   "dev-kfd.device"
      #   "dev-dri-renderD128.device"
      # ];
      # wants = [
      #   "dev-kfd.device"
      #   "dev-dri-renderD128.device"
      # ];
      serviceConfig = {
        Environment = [
          #"HIP_VISIBLE_DEVICES=0"
          #"HSA_ENABLE_SDMA=0"
          #"HSA_USE_SVM=0"
          #"GGML_CUDA_ENABLE_UNIFIED_MEMORY=ON"
          #"ROCBLAS_USE_HIPBLASLT=1"
        ];
        PrivateDevices = lib.mkForce false;
        DevicePolicy = lib.mkForce "auto";
        DeviceAllow = lib.mkForce []; # make sure nothing triggers device filtering

        SystemCallFilter = lib.mkForce null;
        SystemCallErrorNumber = lib.mkForce null;
        #SystemCallLog = "all";
        LimitMEMLOCK = lib.mkForce "infinity";
        # give it owned dirs under /var/lib and /var/cache
        StateDirectory = lib.mkForce "llama-cpp";
        CacheDirectory = lib.mkForce "llama-cpp";
        RuntimeDirectory = "llama-cpp";
        RuntimeDirectoryMode = "0750";
        # Allow access to /proc/meminfo for UMA memory detection
        ProtectProc = lib.mkForce "default";
        ProcSubset = lib.mkForce "all";
        SupplementaryGroups = ["video" "render"];
        MemoryDenyWriteExecute = lib.mkForce false;
        PrivateUsers = lib.mkForce false;
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

        reverse_proxy http://127.0.0.1:5533 {
          header_up Host {upstream_hostport}
        }
      '';
    };
  };
}
