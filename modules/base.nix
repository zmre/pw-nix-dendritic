{
  inputs,
  pkgs,
  ...
}: let
  currentStable = "25.05";

  # nixpkgs configuration (for package settings like allowUnfree)
  nixpkgsConfig = {
    allowUnfree = true;
  };

  # Nix configuration (for flake settings like substituters)
  nixConfig = {
    extra-experimental-features = "nix-command flakes pipe-operators";
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://zmre.cachix.org"
      "https://yazi.cachix.org"
      "https://ghostty.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "zmre.cachix.org-1:WIE1U2a16UyaUVr+Wind0JM6pEXBe43PQezdPKoDWLE="
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
    ];
  };

  stableOverlay = final: prev: {
    stable =
      if final.stdenv.isDarwin
      then
        import inputs.nixpkgs-stable-darwin {
          inherit (final) system;
          config = nixpkgsConfig;
        }
      else
        import inputs.nixpkgs-stable {
          inherit (final) system;
          config = nixpkgsConfig;
        };
  };
in {
  flake-file.description = "My updated nix config now more 'dendritic'";

  # nixpkgs -- unstable is default, stable will be found under pkgs.stable
  flake-file.inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  flake-file.inputs.nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-${currentStable}";
  ## not sure if it matters, but will use -darwin stable version on mac builds
  flake-file.inputs.nixpkgs-stable-darwin.url = "github:nixos/nixpkgs/nixpkgs-${currentStable}-darwin";

  # core needs for the simplified modular "dendritic" setup
  flake-file.inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  flake-file.inputs.flake-file.url = "github:vic/flake-file";
  flake-file.inputs.import-tree.url = "github:vic/import-tree";

  imports = [
    inputs.flake-file.flakeModules.dendritic
    # here's the deal: using allfollow should greatly speed up builds and shrink
    # lock files by standardizing the nixpkgs being used across inputs
    # but this can absolutely cause problems so we'll try it for now, but
    # might just need to manually specify the follows
    #inputs.flake-file.flakeModules.allfollow # not sure I like this all the time
    #inputs.flake-file.flakeModules.nix-auto-follow
    inputs.flake-parts.flakeModules.flakeModules
  ];

  # Workaround
  flake.flakeModules.default = {};

  systems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-darwin"
    "x86_64-linux"
  ];

  flake-file.nixConfig = nixConfig;

  # This module can be imported by any Darwin/NixOS config
  flake.nixosModules.system = {
    nixpkgs.overlays = [stableOverlay];
    nixpkgs.config = nixpkgsConfig;
  };

  flake.darwinModules.system = {
    nixpkgs.overlays = [stableOverlay];
    nixpkgs.config = nixpkgsConfig;
  };
}
