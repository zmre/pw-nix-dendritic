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
    flake-file.inputs.darwin.url = "github:nix-darwin/nix-darwin";
    flake-file.inputs.darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  options = {
    flake = mkSubmoduleOptions {
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
