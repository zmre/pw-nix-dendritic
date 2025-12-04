{inputs, ...}: let
  username = "pwalsh";
  hostname = "aironcore";
  system = "x86_64-linux";
in {
  imports = [inputs.home-manager.flakeModules.home-manager];
  flake.homeConfigurations.${hostname} = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    modules = with inputs.self.modules.homeManager; [
      shell
      filemanagement
      ai
      iron
      dev
      vim

      ({pkgs, ...}: {
        nixpkgs.config.allowUnfree = true;
        services.ollama = {
          enable = true;
          package = pkgs.ollama-cuda;
          acceleration = "cuda";
          host = "0.0.0.0";
          environmentVariables = {
            OLLAMA_CONTEXT_LENGTH = "25000";
            OLLAMA_MAX_LOADED_MODELS = "2";
            OLLAMA_MAX_QUEUE = "512";
          };
        };

        home.packages = with pkgs; [
          vulkan-headers
          vulkan-loader
          cudaPackages.cudatoolkit
          #cudaPackages.cudnn
          cudaPackages.nccl
          cudaPackages.cuda_cccl
        ];
        programs.zsh.shellAliases = {
          btop = "/usr/bin/btop";
        };
        home.sessionVariables = {
          LD_PRELOAD = "/usr/lib/x86_64-linux-gnu/libcuda.so.1:/usr/lib/x86_64-linux-gnu/libnvidia-ptxjitcompiler.so.1";
          # LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.vulkan-loader}/lib:${pkgs.cudatoolkit}/lib:${pkgs.cudaPackages.nccl}/lib:/usr/lib/x86_64-linux-gnu/libcuda.so.1:/usr/lib/x86_64-linux-gnu/libnvidia-ptxjitcompiler.so.1";
          CUDA_PATH = "${pkgs.cudatoolkit}";
          VULKAN_SDK = "${pkgs.vulkan-headers}";
        };
      })
      network
      {
        hardware.gpu = "cuda";
        home.username = username;
        home.homeDirectory = "/home/${username}";
        home.stateVersion = "25.05";
      }
    ];
  };
}
