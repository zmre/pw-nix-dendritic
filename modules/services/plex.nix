{config, ...}: {
  flake.nixosModules.plex = {pkgs, ...}: {
    imports = [config.flake.nixosModules.comskip];
    # TODO: add comskip as a post processor for jellyfin
    services.jellyfin.enable = true;
    services.jellyfin.openFirewall = true;
    services.plex.enable = true;
    services.plex.extraPlugins = [
      (builtins.path {
        name = "Audnexus.bundle";
        path = pkgs.fetchFromGitHub {
          owner = "djdembeck";
          repo = "Audnexus.bundle";
          rev = "v1.3.2";
          #sha256 = lib.fakeSha256;
          sha256 = "sha256-BpwyedIjkXS+bHBsIeCpSoChyWCX5A38ywe71qo3tEI=";
        };
      })
    ];
    services.plex.openFirewall = true;
  };
}
