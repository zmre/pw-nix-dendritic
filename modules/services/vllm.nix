{inputs, ...}: {
  flake.nixosModules.vllm = {
    pkgs,
    lib,
    config,
    ...
  }: let
    inherit (config.hardware) gpu;
    # vLLM listens on this port (with host networking, no port mapping needed)
    vllmPort = 11322;
    # Caddy external port with TLS
    vllmExternalPort = 11323;
    # Model to serve - Qwen3-Coder-30B-A3B-Instruct FP8 (~30GB)
    # Official Qwen coding model with FP8 quantization
    model = "Qwen/Qwen3-Coder-30B-A3B-Instruct-FP8";
    # Docker image with ROCm 7.0 and vLLM 0.11.2
    vllmImage = "rocm/vllm:rocm7.0.0_vllm_0.11.2_20251210";
  in {
    # Note: hardware-options module must be imported at the host level
    # This module uses config.hardware.gpu which is defined there

    # Enable Podman with host networking to avoid bridge issues on kernel 6.17
    virtualisation.podman = {
      enable = true;
      dockerCompat = true; # Creates docker alias
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    # Ensure the vllm user exists and has proper groups
    users.users.vllm = {
      isSystemUser = true;
      group = "vllm";
      extraGroups = ["video" "render"];
    };
    users.groups.vllm = {};

    # Create data directories
    systemd.tmpfiles.rules = [
      "d /var/lib/vllm 0755 vllm vllm -"
      "d /var/lib/vllm/huggingface 0755 vllm vllm -"
    ];

    # vLLM container configuration
    virtualisation.oci-containers = {
      backend = "podman";

      containers.vllm = {
        image = vllmImage;
        autoStart = true;

        # Use host networking to bypass bridge creation issues on kernel 6.17
        # No port mapping needed - container binds directly to host ports
        extraOptions = [
          # Host networking - bypasses netavark bridge issues
          "--network=host"
          # GPU devices
          "--device=/dev/kfd"
          "--device=/dev/dri"
          # Add to video group for GPU access
          "--group-add=video"
          # Security options required for ROCm
          "--security-opt=seccomp=unconfined"
          # Shared memory for PyTorch tensor operations
          "--shm-size=16g"
          # Additional capabilities sometimes needed
          "--cap-add=SYS_PTRACE"
          # Ulimits for performance
          "--ulimit=memlock=-1"
          "--ulimit=stack=67108864"
        ];

        # Environment variables for ROCm and vLLM
        environment = {
          # HuggingFace cache location
          HF_HOME = "/cache";
          HUGGING_FACE_HUB_TOKEN = ""; # Set via environmentFiles if needed
          # ROCm settings for gfx1151 (AMD Ryzen AI Max+ 395)
          # May need HSA_OVERRIDE_GFX_VERSION if library issues occur
          # HSA_OVERRIDE_GFX_VERSION = "11.0.0";
          # PyTorch memory settings
          PYTORCH_HIP_ALLOC_CONF = "expandable_segments:True";
          # vLLM V1 is default, ensure it's enabled
          VLLM_USE_V1 = "1";
        };

        # Mount the HuggingFace cache for model storage
        volumes = [
          "/var/lib/vllm/huggingface:/cache"
        ];

        # vLLM serve command - GPTQ-Int4 quantized model (~15GB)
        # With quantization, we have ~45-50GB free for KV cache
        # Binds to localhost only for security (Caddy handles external access)
        cmd = [
          "vllm"
          "serve"
          model
          "--host"
          "127.0.0.1"
          "--port"
          (toString vllmPort)
          "--enforce-eager"
          #"--enable-chunked-prefill"
          # Use 95% of 64GB GPU memory - quantized model is much smaller
          "--gpu-memory-utilization"
          "0.95"
          # Can use larger batch with quantized model
          "--max-num-batched-tokens"
          "4096"
          # More concurrent sequences
          "--max-num-seqs"
          "8"
          # Higher context length now that we have memory headroom
          "--max-model-len"
          "32768"
          # Enable prefix caching for better throughput
          "--enable-prefix-caching"
          # Trust HuggingFace model code
          "--trust-remote-code"
          # Served model name for API
          "--served-model-name"
          "qwen3-coder"
          # Disable usage stats
          "--disable-log-stats"
          # Allow tool use
          "--enable-auto-tool-choice"
          "--tool-call-parser"
          "hermes"
        ];
      };
    };

    # Open firewall for external TLS port
    networking.firewall.allowedTCPPorts = [vllmExternalPort];

    # Caddy reverse proxy with TLS via Tailscale
    services.caddy.virtualHosts."${config.networking.hostName}.${config.networking.domain}:${toString vllmExternalPort}" = {
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
        # Set CORS headers for cross-origin requests
        @options method OPTIONS
        handle @options {
          header Access-Control-Allow-Origin {http.request.header.origin}
          header Access-Control-Allow-Credentials true
          header Access-Control-Allow-Methods "GET, POST, OPTIONS"
          header Access-Control-Allow-Headers "Authorization, Content-Type"
          header Access-Control-Max-Age 1728000
          respond "" 204
        }

        handle {
          # Add CORS headers
          header Access-Control-Allow-Origin {http.request.header.origin}
          header Access-Control-Allow-Credentials true
          header Access-Control-Allow-Headers "Authorization, Content-Type"

          reverse_proxy http://127.0.0.1:${toString vllmPort}
        }
      '';
    };
  };
}
