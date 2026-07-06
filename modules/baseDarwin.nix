{
  self,
  lib,
  flake-parts-lib,
  moduleLocation,
  ...
}: let
  inherit
    (lib)
    mapAttrs
    mkOption
    types
    ;
  inherit
    (flake-parts-lib)
    mkSubmoduleOptions
    ;
in {
  config = {
    # TODO: revert to plain "github:nix-darwin/nix-darwin" once this PR merges:
    # https://github.com/nix-darwin/nix-darwin/pull/1819 (manual build broken by
    # nixos-render-docs removing --toc-depth in favor of --sidebar-depth)
    flake-file.inputs.darwin.url = "github:nix-darwin/nix-darwin?ref=pull/1819/head";
    flake-file.inputs.darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  options = {
    flake = mkSubmoduleOptions {
      darwinConfigurations = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = {};
        description = ''
          Nix-Darwin system configurations.
        '';
      };
      darwinModules = mkOption {
        type = types.lazyAttrsOf types.deferredModule;
        default = {};
        apply = mapAttrs (k: v: {
          _class = "darwin";
          _file = "${toString moduleLocation}#darwinModules.${k}";
          imports = [v];
        });
        description = ''
          Nix-Darwin modules.

          You may use this for reusable pieces of configuration, service modules, etc.
        '';
      };
    };
  };
}
