{
  flake.modules.homeManager.calibre-web = {
    programs.calibre.enable = true;
  };
  flake.nixosModules.calibre-web = {config, ...}: let
    internalPort = 7082;
    remotePort = 8083;
  in {
    # calibre-web is broken in nixpkgs-unstable as of 2026-07-13:
    # 1. pip-chill (test-only dep via scholarly -> free-proxy) imports
    #    pkg_resources, which setuptools no longer provides on python 3.14.
    #    Safe to skip its import check: it's never imported at runtime.
    # 2. chardet 6.x and certifi 2026.4.x exceed upstream version pins and
    #    nixpkgs' pythonRelaxDeps list doesn't include them yet.
    # TODO: remove once nixpkgs bumps/fixes calibre-web upstream.
    nixpkgs.overlays = [
      (final: prev: {
        pythonPackagesExtensions =
          prev.pythonPackagesExtensions
          ++ [
            (pfinal: pprev: {
              pip-chill = pprev.pip-chill.overridePythonAttrs (_: {
                doCheck = false;
                pythonImportsCheck = [];
              });
            })
          ];
        calibre-web = prev.calibre-web.overridePythonAttrs (old: {
          pythonRelaxDeps = (old.pythonRelaxDeps or []) ++ ["chardet" "certifi"];
        });
      })
    ];

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
