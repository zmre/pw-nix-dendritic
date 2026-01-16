{inputs, ...}: {
  flake-file.inputs.city-explorer.url = "github:zmre/city-explorer";
  flake-file.inputs.city-explorer.inputs.nixpkgs.follows = "nixpkgs";
  flake-file.inputs.city-explorer.inputs.flake-utils.follows = "flake-utils";

  flake.nixosModules.city-explorer = {
    config,
    pkgs,
    ...
  }: let
    remotePort = 8090;
    inherit (pkgs.stdenvNoCC.hostPlatform) system;
  in {
    networking.firewall.allowedTCPPorts = [remotePort];
    services.caddy.virtualHosts."${config.networking.hostName}.${config.networking.domain}:${toString remotePort}" = {
      listenAddresses = ["0.0.0.0"];
      extraConfig = ''
        encode {
          zstd
          gzip
          minimum_length 1024
        }

        root * ${inputs.city-explorer.packages.${system}.static}
        file_server {
          index index.html index.htm
        }
      '';
    };
  };
}
