{
  flake.darwinModules.terminfo = {
    pkgs,
    lib,
    ...
  }: {
    environment.systemPackages =
      [
        pkgs.wezterm.terminfo # this one does not need compilation
        # avoid compiling desktop stuff when doing cross nixos
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform) [
        pkgs.kitty.terminfo
        pkgs.termite.terminfo
      ];
  };

  flake.nixosModules.terminfo = {
    pkgs,
    lib,
    ...
  }: {
    environment.systemPackages =
      [
        pkgs.wezterm.terminfo # this one does not need compilation
        # avoid compiling desktop stuff when doing cross nixos
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform) [
        pkgs.foot.terminfo
        pkgs.ghostty.terminfo
        pkgs.kitty.terminfo
        pkgs.termite.terminfo
      ];
  };
}
