{inputs, ...}: {
  flake.nixosModules.ollama = {
    pkgs,
    lib,
    config,
    ...
  }: let
    inherit (config.hardware) gpu;
    # Package selection based on GPU type
    # Note: acceleration option was removed - now just set the package variant
    ollamaPkg =
      if gpu == "cuda"
      then pkgs.ollama-cuda
      else if gpu == "rocm"
      then pkgs.ollama-rocm
      else pkgs.ollama;
    ollamaLibrary =
      if gpu == "cuda"
      then "cuda_v11 cuda_v12"
      else if gpu == "rocm"
      then "rocm_v6"
      else "cpu cpu_avx cpu_avx2";
  in {
    # Note: hardware-options module must be imported at the host level
    # This module uses config.hardware.gpu which is defined there

    users.users.ollama = {
      isNormalUser = false;
      extraGroups = ["ollama" "video" "render"];
    };
    boot.kernelParams = [
      # TODO: try to remove these in awhile; working around some errors
      "amdgpu.cwsr_enable=0"
      "amdgpu.ppfeaturemask=0xf7fff"
    ];
    services.ollama = {
      enable = true;
      package = ollamaPkg;
      group = "ollama";
      host = "127.0.0.1";
      port = 11433; # non-standard because we're fronting with caddy for tls and cert management
      loadModels = [
        "deepseek-coder-v2:16b"
        "devstral-small-2:24b"
        "gemma3:27b"
        "glm-4.7-flash"
        "glm4:9b"
        "gpt-oss:20b"
        "gpt-oss-safeguard:120b"
        "llama3:8b"
        "magistral:24b"
        "ministral-3:14b"
        "nemotron-3-nano:latest"
        "qwen3-coder:30b"
        "qwen3:30b"
        "qwen3:30b-thinking"
      ];
      openFirewall = false;
      home = "/var/lib/ollama";
      user = "ollama";
      #rocmOverrideGfx = lib.mkIf (gpu == "rocm") "11.0.2";
      environmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "128000";
        OLLAMA_MAX_LOADED_MODELS = "3";
        # Optimize GPU usage -- load everything in GPU
        OLLAMA_GPU_LAYERS = "999";
        # Keep model in RAM longer
        OLLAMA_KEEP_ALIVE = "30m";
        OLLAMA_MAX_QUEUE = "512";
        #OLLAMA_DEBUG = "2";
        OLLAMA_LLM_LIBRARY = ollamaLibrary;
        AMD_LOG_LEVEL = "3";
        OLLAMA_ORIGINS = "*"; # Allow requests through Caddy reverse proxy
      };
    };
    networking.firewall.allowedTCPPorts = [11434];
    services.caddy.virtualHosts."${config.networking.hostName}.${config.networking.domain}:11434" = {
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

        reverse_proxy http://127.0.0.1:11433 {
          header_up Host {upstream_hostport}
        }
      '';
    };
  };
}
