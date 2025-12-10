{
  inputs,
  pkgs,
  lib,
  ...
}: let
  currentStable = "25.11";

  # nixpkgs configuration (for package settings like allowUnfree)
  nixpkgsConfig = {
    allowUnfree = true;
  };

  # Nix configuration (for flake settings like substituters)
  nixConfig = {
    extra-experimental-features = "nix-command flakes pipe-operators";
    download-buffer-size = 536870912; # 512 MiB (increased from default 64 MiB)
  };

  stableOverlay = final: prev: {
    stable =
      if final.stdenv.isDarwin
      then
        import inputs.nixpkgs-stable-darwin {
          system = final.stdenv.hostPlatform.system;
          config = nixpkgsConfig;
        }
      else
        import inputs.nixpkgs-stable {
          system = final.stdenv.hostPlatform.system;
          config = nixpkgsConfig;
        };
  };
in {
  # Declare flake.nixConfig as a mergeable option so multiple modules can contribute
  options.flake.nixConfig = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = {};
    description = "Nix configuration settings that get merged across modules";
  };

  imports = [
    inputs.flake-file.flakeModules.dendritic
    # here's the deal: using allfollow should greatly speed up builds and shrink
    # lock files by standardizing the nixpkgs being used across inputs
    # but this can absolutely cause problems so we'll try it for now, but
    # might just need to manually specify the follows
    # update: alas, things broke
    #inputs.flake-file.flakeModules.allfollow # not sure I like this all the time
    #inputs.flake-file.flakeModules.nix-auto-follow
    inputs.flake-parts.flakeModules.flakeModules
  ];

  config = {
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

    # These are common dependencies across flakes; I want to shrink my lock file and closures
    # by directly referencing them and then having various flake files follow them.
    # Note: the auto file stuff is cool, but you need to be able to disable selectively, so here we are
    flake-file.inputs.flake-utils.url = "github:numtide/flake-utils";
    flake-file.inputs.flake-compat.url = "github:NixOS/flake-compat";

    # Workaround
    flake.flakeModules.default = {};

    systems = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];

    flake-file.nixConfig = nixConfig;
    flake.nixConfig = nixConfig;

    # This module can be imported by any Darwin/NixOS config
    flake.nixosModules.system = {
      nixpkgs.overlays = [stableOverlay];
      nixpkgs.config = nixpkgsConfig;
    };

    flake.darwinModules.system = {
      nixpkgs.overlays = [stableOverlay];
      nixpkgs.config = nixpkgsConfig;
    };
  };
}
