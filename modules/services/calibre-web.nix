{
  flake.modules.homeManager.calibre-web = {
    programs.calibre.enable = true;
  };
  flake.nixosModules.calibre-web = {config, ...}: let
    internalPort = 7082;
    remotePort = 8083;
  in {
    services.calibre-web = {
      enable = true;
      listen.port = internalPort;
      # allow local net devices without tailscale to connect
      listen.ip = "0.0.0.0";
      options = {
        # calibreLibrary = "/var/lib/calibre-web/db";
        enableBookConversion = true;
        enableBookUploading = true;
      };
    };
    networking.firewall.allowedTCPPorts = [remotePort];
    services.caddy.virtualHosts."${config.networking.hostName}.${config.networking.domain}:${builtins.toString remotePort}" = {
      listenAddresses = ["0.0.0.0"];
      extraConfig = ''
        tls {
          get_certificate tailscale
        }
        encode {
          zstd
          gzip
          minimum_length 1024
        }
        reverse_proxy http://127.0.0.1:${builtins.toString internalPort} {
          header_up Host {http.request.host}

          transport http {
            versions 1.1
          }
        }
        request_body {
          max_size 10GB
        }
      '';
    };
  };
}
