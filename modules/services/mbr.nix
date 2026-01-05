{inputs, ...}: {
  # Declare flake input for mbr-markdown-browser
  flake-file.inputs.mbr-markdown-browser.url = "github:zmre/mbr-markdown-browser";

  flake.nixosModules.mbr = {
    pkgs,
    lib,
    config,
    ...
  }: let
    internalPort = 5200;
    remotePort = 5201;
    mbrPkg = inputs.mbr-markdown-browser.packages.${pkgs.system}.default;
    dataDir = "/var/lib/mbr";
    contentPath = "${dataDir}/magic/content";
    inherit (config.system) primaryUser;
  in {
    # Create directory structure
    systemd.tmpfiles.rules = [
      "d ${dataDir} 0755 ${primaryUser} users -"
      "L+ ${dataDir}/magic - - - - /home/${primaryUser}/public/magic"
    ];

    # Custom systemd service (no NixOS module exists)
    systemd.services.mbr = {
      description = "MBR Markdown Browser Server";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      serviceConfig = {
        Type = "simple";
        User = primaryUser;
        Group = "users";
        ExecStart = "${mbrPkg}/bin/mbr -s ${contentPath}";
        Restart = "on-failure";
        RestartSec = "5s";
        WorkingDirectory = "${dataDir}/magic";
      };
    };

    # Firewall - open external port only
    networking.firewall.allowedTCPPorts = [remotePort];

    # Caddy reverse proxy with TLS via Tailscale
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
        reverse_proxy http://127.0.0.1:${builtins.toString internalPort}
      '';
    };
  };
}
