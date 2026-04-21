{
  flake.darwinModules.terminfo = {
    pkgs,
    lib,
    ...
  }: let
    terminfos =
      [
        pkgs.wezterm.terminfo
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform) [
        pkgs.kitty.terminfo
        pkgs.termite.terminfo
        pkgs.ghostty-bin.terminfo
        pkgs.alacritty.terminfo
      ];
  in {
    # We can be more thorough (bloat the system, but cover all terminals) with the line below
    # which would replace the systemPackages and extraInit stuff below.
    #environment.enableAllTerminfo = true;

    environment.systemPackages = terminfos;

    environment.extraInit = ''
      export TERMINFO_DIRS="''${TERMINFO_DIRS:+$TERMINFO_DIRS:}${
        lib.concatMapStringsSep ":" (p: "${p}/share/terminfo") terminfos
      }"
    '';
  };

  flake.nixosModules.terminfo = {
    pkgs,
    lib,
    ...
  }: let
    terminfos =
      [
        pkgs.wezterm.terminfo
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform) [
        pkgs.foot.terminfo
        pkgs.kitty.terminfo
        pkgs.termite.terminfo
        pkgs.ghostty.terminfo
        pkgs.alacritty.terminfo
      ];
  in {
    # We can be more thorough (bloat the system, but cover all terminals) with the line below
    # which would replace the systemPackages and extraInit stuff below.
    #environment.enableAllTerminfo = true;

    environment.systemPackages = terminfos;

    environment.extraInit = ''
      export TERMINFO_DIRS="''${TERMINFO_DIRS:+$TERMINFO_DIRS:}${
        lib.concatMapStringsSep ":" (p: "${p}/share/terminfo") terminfos
      }"
    '';
  };
}
