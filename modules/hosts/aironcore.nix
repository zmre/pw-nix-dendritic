{inputs, ...}: let
  username = "pwalsh";
  hostname = "aironcore";
  system = "x86_64-linux";
in {
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ];
  flake.homeConfigurations.${hostname} = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    modules = with inputs.self.modules.homeManager; [
      inputs.nix-index-database.homeModules.default
      hardware-options
      shell
      filemanagement
      network
      ai
      iron
      dev
      vim

      ({pkgs, ...}: {
        home.packages = with pkgs; [
          ollama
        ];
        programs.zsh.shellAliases = {
          btop = "/usr/bin/btop";
        };
      })
      {
        hardware.gpu = "cuda";
        home.username = username;
        home.homeDirectory = "/home/${username}";
        home.stateVersion = "25.05";
      }
    ];
  };
}
