{
  flake.nixosModules.ollama = {pkgs, ...}: {
    users.users.ollama = {
      isNormalUser = false;
      extraGroups = ["ollama"];
    };
    services = {
      ollama = {
        enable = true;
        acceleration = "rocm";
        group = "ollama";
        host = "0.0.0.0";
        loadModels = ["gpt-oss:20b" "gemma3:27b" "qwen3-coder:30b" "llama3:8b" "deepseek-r1:32b" "gpt-oss:120b" "llama3.1:70b" "glm4:9b" "qwen3:30b"];
        openFirewall = true;
        home = "/var/lib/ollama";
        #models = "/home/ollama/models";
        user = "ollama";
        # The below just sets HSA_OVERRIDE_GFX_VERSION
        # Sources disagree but looks like it should be either 11.0.0 or 11.0.2
        environmentVariables = {
          OLLAMA_CONTEXT_LENGTH = "25000";
          # Set memory limits
          OLLAMA_MAX_LOADED_MODELS = "2";
          OLLAMA_MAX_QUEUE = "512";
        };
      };
    };
  };
}
