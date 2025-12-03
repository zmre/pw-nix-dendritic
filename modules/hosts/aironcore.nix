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
      network
      {
        home.username = username;
        home.homeDirectory = "/home/${username}";
        home.stateVersion = "25.05";
      }
    ];
  };
}
