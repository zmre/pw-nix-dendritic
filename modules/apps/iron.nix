{inputs, ...}: {
  flake-file.inputs.rust-overlay.url = "github:oxalica/rust-overlay";
  flake-file.inputs.ironhide.url = "github:IronCoreLabs/ironhide";
  flake-file.inputs.ironhide.inputs.nixpkgs.follows = "nixpkgs";
  flake-file.inputs.ironhide.inputs.rust-overlay.follows = "rust-overlay";
  flake-file.inputs.ironhide.inputs.flake-utils.follows = "flake-utils";
  flake-file.inputs.ironoxide.url = "github:IronCoreLabs/ironoxide-cli";
  flake-file.inputs.ironoxide.inputs.rust-overlay.follows = "rust-overlay";
  flake-file.inputs.ironoxide.inputs.nixpkgs.follows = "nixpkgs";
  flake-file.inputs.ironoxide.inputs.flake-utils.follows = "flake-utils";

  flake.modules.homeManager.iron = {pkgs, ...}: let
    system = pkgs.stdenvNoCC.hostPlatform.system;
  in {
    home.packages = [
      inputs.ironhide.packages.${system}.ironhide
      inputs.ironoxide.packages.${system}.ironoxide-cli
    ];
  };
}
