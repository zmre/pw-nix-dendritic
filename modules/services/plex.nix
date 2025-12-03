{inputs, ...}: {
  flake.nixosModules.plex = {
    pkgs,
    config,
    lib,
    ...
  }: {
    imports = [inputs.self.nixosModules.comskip];

    # Only evaluate on Linux systems to avoid cross-platform check issues
    config = lib.mkIf pkgs.stdenv.isLinux (let
      # Make the plugin fetch lazy - only evaluated when this config is actually merged
      audnexusPlugin = pkgs.fetchFromGitHub {
        owner = "djdembeck";
        repo = "Audnexus.bundle";
        rev = "v1.3.2";
        sha256 = "sha256-BpwyedIjkXS+bHBsIeCpSoChyWCX5A38ywe71qo3tEI=";
      };
    in {
      # TODO: add comskip as a post processor for jellyfin
      services.jellyfin.enable = true;
      services.jellyfin.openFirewall = true;
      services.plex.enable = true;
      services.plex.extraPlugins = [
        (builtins.path {
          name = "Audnexus.bundle";
          path = audnexusPlugin;
        })
      ];
      services.plex.openFirewall = true;
    });
  };
}
