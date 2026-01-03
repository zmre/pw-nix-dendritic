{
  flake.nixosModules.audiobookshelf = {config, ...}: let
    internalPort = 7999;
    remotePort = 8000;
  in {
    services.audiobookshelf = {
      enable = true;
      port = internalPort;
      host = "127.0.0.1";
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
