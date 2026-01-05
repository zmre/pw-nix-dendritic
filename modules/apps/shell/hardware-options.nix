{inputs, ...}: let
  # Shared option definition for GPU acceleration
  gpuOption = lib: {
    options.hardware.gpu = lib.mkOption {
      type = lib.types.enum ["none" "cuda" "rocm"];
      default = "none";
      description = "GPU acceleration type for packages like btop and ollama";
    };
  };
in {
  # Hardware options for home-manager configs
  flake.modules.homeManager.hardware-options = {lib, ...}: gpuOption lib;

  # Hardware options for NixOS configs (also sets nixpkgs.config support flags)
  flake.nixosModules.hardware-options = {
    lib,
    config,
    ...
  }: {
    options = {
      hardware.gpu = lib.mkOption {
        type = lib.types.enum ["none" "cuda" "rocm"];
        default = "none";
        description = "GPU acceleration type for packages like btop and ollama";
      };

      # Equivalent to Darwin's system.primaryUser for NixOS
      system.primaryUser = lib.mkOption {
        type = lib.types.str;
        description = "The primary user account for this system, used by services that need a specific user.";
      };
    };

    config.nixpkgs.config = {
      cudaSupport = config.hardware.gpu == "cuda";
      rocmSupport = config.hardware.gpu == "rocm";
      cudaVersion = "12";
    };
  };
}
