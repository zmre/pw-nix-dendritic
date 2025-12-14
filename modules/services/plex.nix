{inputs, ...}: {
  flake.nixosModules.plex = {
    pkgs,
    config,
    lib,
    ...
  }:
  #let
  #defaultPlexPort = 32400;
  #defaultJellyPort = 8096;
  #in
  {
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
      services.jellyfin.enable = false;
      services.jellyfin.openFirewall = true;

      # Things I did to get TLS working:
      # sudo tailscale cert fully.qualified.tailscale.host.name.ts.net
      # openssl pkcs12 -export -out fqdn.ts.net.pfx -inkey fqdn.ts.net.key -in fqdn.ts.net.crt -certpbe AES-256-CBC -keypbe AES-256-CBC -macalg SHA256
      # When prompted for a password, I typed something in, which we'll need in a moment.
      # sudo mv *.pfx /var/lib/plex
      # sudo chown plex:plex /var/lib/plex/*.pfx
      # In plex UI under settings -> network, I put /var/lib/plex/fqdn.ts.net.pfx into the "Custom certificate location" field and the password in the "customer certificate encryption key" field
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
