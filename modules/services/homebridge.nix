{
  flake.nixosModules.homebridge = {config, ...}: {
    services.homebridge = {
      enable = true;
      openFirewall = true;
      environmentFile = "/var/lib/homebridge/vars";
    };
  };
}
