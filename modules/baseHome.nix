{inputs, ...}: {
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake.nixosModules.common = {pkgs, ...}: {
    imports = [inputs.home-manager.nixosModules.default];
  };
  flake.darwinModules.common = {pkgs, ...}: {
    imports = [inputs.home-manager.darwinModules.default];
  };
}
