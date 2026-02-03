{inputs, ...}: {
  flake.nixosModules.llamacpp-qwen235b = {
    pkgs,
    config,
    lib,
    ...
  }: {
    # Qwen3-235B-A22B service (~112GB Q3_K_XL quant)
    # Largest MoE - reduced context and small batches due to size

    environment.systemPackages = [pkgs.llama-cpp];

    services.llama-cpp = {
      enable = true;
      package = pkgs.llama-cpp;
      host = "127.0.0.1";
      port = 8081;
      model = "/var/lib/models/Qwen3-235B-A22B-Q3_K_XL.gguf";
      extraFlags = [
        "--no-mmap" # CRITICAL for ROCm (2X+ perf)
        "--mlock" # Keep in memory
        "--gpu-layers"
        "999" # All layers to GPU
        "--threads"
        "16" # CPU threads for non-GPU ops
        "--threads-batch"
        "16"
        "--ctx-size"
        "8192" # Start small, increase after testing
        "--batch-size"
        "256" # Small batch for large MoE
        "--ubatch-size"
        "128"
        "--flash-attn"
        "off" # Disabled - gfx1151 crashes during graph_reserve with flash-attn
        "--cache-type-k"
        "q4_0"
        "--cache-type-v"
        "q4_0"
        "--jinja"
        "--verbose"
        "--log-file"
        "/tmp/llama-qwen235b.log"
      ];
    };

    systemd.services.llama-cpp = {
      environment = {
        ROCBLAS_USE_HIPBLASLT = "1";
        HSA_OVERRIDE_GFX_VERSION = "11.0.0"; # Required for gfx1151 (Strix Halo)
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
