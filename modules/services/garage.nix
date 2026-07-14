{
  flake.nixosModules.garage = {
    pkgs,
    config,
    ...
  }: let
    s3Port = 3900; # S3 API (localhost only)
    rpcPort = 3901; # inter-node RPC (localhost only, single node)
    webPort = 3902; # static website endpoint (localhost only)
    adminPort = 3903; # admin API / metrics (localhost only)
    remoteS3Port = 3910; # S3 API via Caddy with tailscale TLS
  in {
    # One-time setup before first activation:
    #   sudo sh -c 'umask 077; printf "GARAGE_RPC_SECRET=%s\nGARAGE_ADMIN_TOKEN=%s\n" "$(openssl rand -hex 32)" "$(openssl rand -hex 32)" > /etc/garage.env'
    #
    # One-time cluster layout after first start (single node):
    #   sudo garage status                      # note the node ID
    #   sudo garage layout assign -z dc1 -c 1T <node-id-prefix>
    #   sudo garage layout apply --version 1
    #
    # Then create buckets/keys:
    #   sudo garage bucket create mybucket
    #   sudo garage key create mykey            # prints key ID + secret
    #   sudo garage bucket allow --read --write mybucket --key mykey
    #
    # S3 endpoint (path-style): https://avalon.savannah-basilisk.ts.net:3910
    # region: garage
    services.garage = {
      enable = true;
      package = pkgs.garage_2;
      # Holds GARAGE_RPC_SECRET (and GARAGE_ADMIN_TOKEN) so they stay out of
      # the world-readable /etc/garage.toml and the nix store
      environmentFile = "/etc/garage.env";
      settings = {
        replication_factor = 1;
        db_engine = "lmdb";
        # metadata on /var/lib/garage (rpool SSD) via StateDirectory defaults

        rpc_bind_addr = "127.0.0.1:${builtins.toString rpcPort}";
        rpc_public_addr = "127.0.0.1:${builtins.toString rpcPort}";

        s3_api = {
          api_bind_addr = "127.0.0.1:${builtins.toString s3Port}";
          s3_region = "garage";
          root_domain = ".s3.${config.networking.hostName}.${config.networking.domain}";
        };

        s3_web = {
          bind_addr = "127.0.0.1:${builtins.toString webPort}";
          root_domain = ".web.${config.networking.hostName}.${config.networking.domain}";
        };

        admin.api_bind_addr = "127.0.0.1:${builtins.toString adminPort}";
      };
    };

    networking.firewall.allowedTCPPorts = [remoteS3Port];
    services.caddy.virtualHosts."${config.networking.hostName}.${config.networking.domain}:${builtins.toString remoteS3Port}" = {
      listenAddresses = ["0.0.0.0"];
      extraConfig = ''
        tls {
          get_certificate tailscale
        }
        # No Host override: SigV4 signs the Host header including port, and
        # reverse_proxy already forwards the original Host untouched
        reverse_proxy http://127.0.0.1:${builtins.toString s3Port}
        request_body {
          max_size 50GB
        }
      '';
    };
  };
}
