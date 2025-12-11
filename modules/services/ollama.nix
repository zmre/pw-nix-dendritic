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
  in {
    imports = [inputs.self.nixosModules.hardware-options];

    users.users.ollama = {
      isNormalUser = false;
      extraGroups = ["ollama"];
    };
    services.ollama = {
      enable = true;
      package = ollamaPkg;
      group = "ollama";
      host = "0.0.0.0";
      loadModels = ["gpt-oss:20b" "gemma3:27b" "qwen3-coder:30b" "llama3:8b" "deepseek-r1:32b" "gpt-oss:120b" "llama3.1:70b" "glm4:9b" "qwen3:30b"];
      openFirewall = true;
      home = "/var/lib/ollama";
      user = "ollama";
      rocmOverrideGfx = lib.mkIf (gpu == "rocm") "11.0.2";
      environmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "25000";
        OLLAMA_MAX_LOADED_MODELS = "2";
        OLLAMA_MAX_QUEUE = "512";
      };
    };
  };
}
