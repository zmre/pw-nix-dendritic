{inputs, ...}: {
  # Ledgeline: local hledger GUI (axum server + wry/tao webview) with an
  # embedded SvelteKit SPA. A proper flake (github:zmre/ledgeline, private).
  # On darwin `packages.default` (macDist) is a symlinkJoin of the CLI binary
  # (`bin/ledgeline`, real SPA baked in) plus `Applications/Ledgeline.app`, so
  # home-manager puts the CLI on PATH and copies the app into ~/Applications.
  # Builds pull from zmre.cachix.org (already a configured substituter).
  # NOTE: private repo -- eval/build needs GitHub auth (nix `access-tokens`).
  flake-file.inputs.ledgeline.url = "github:zmre/ledgeline";

  # Kept as a slot for any future Homebrew casks under this feature.
  flake.darwinModules.finance-gui = {
    homebrew.casks = [];
  };

  flake.modules.homeManager.finance-gui = {
    pkgs,
    lib,
    ...
  }: let
    inherit (pkgs.stdenvNoCC.hostPlatform) system;
  in {
    home.packages = lib.optionals pkgs.stdenv.isDarwin [
      inputs.ledgeline.packages.${system}.default
    ];
  };
}
