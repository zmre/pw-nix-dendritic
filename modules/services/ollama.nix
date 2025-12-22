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
    imports = [inputs.self.nixosModules.hardware-options];

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
      loadModels = ["gpt-oss:20b" "gemma3:27b" "qwen3-coder:30b" "llama3:8b" "deepseek-r1:32b" "gpt-oss:120b" "llama3.1:70b" "glm4:9b" "qwen3:30b-a3b"]; # qwen3:30b
      openFirewall = false;
      home = "/var/lib/ollama";
      user = "ollama";
      #rocmOverrideGfx = lib.mkIf (gpu == "rocm") "11.0.2";
      environmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "128000";
        OLLAMA_MAX_LOADED_MODELS = "3";
        OLLAMA_MAX_QUEUE = "512";
        #OLLAMA_DEBUG = "2";
        OLLAMA_LLM_LIBRARY = ollamaLibrary;
        #AMD_LOG_LEVEL = "3";
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
            # Set CORS headers
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

          reverse_proxy http://127.0.0.1:11433
        }
      '';
    };
  };
}
