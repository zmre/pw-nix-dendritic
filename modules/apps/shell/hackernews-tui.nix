{inputs, ...}: {
  flake-file.inputs.hackernews-tui.url = "github:aome510/hackernews-TUI";
  flake-file.inputs.hackernews-tui.flake = false;

  flake.modules.homeManager.hackernews-tui = {pkgs, ...}: let
    hackernews-tui = pkgs.rustPlatform.buildRustPackage {
      name = "hackernews-tui";
      pname = "hackernews-tui";
      cargoLock = {lockFile = inputs.hackernews-tui + /Cargo.lock;};
      buildInputs =
        [pkgs.pkg-config pkgs.libiconv]
        ++ pkgs.lib.optionals pkgs.stdenv.isDarwin
        [pkgs.apple-sdk];
      src = inputs.hackernews-tui;
    };
  in {
    home.packages = [
      pkgs.hackernews-tui
    ];
    home.file.".config/hn-tui.toml".text = ''
      [theme.palette]
      background = "#242424"
      foreground = "#f6f6ef"
      selection_background = "#4a4c4c"
      selection_foreground = "#d8dad6"
    '';
  };
}
