{
  flake.nixosModules.caddy = {config, ...}: {
    services.caddy = {
      enable = true;
      enableReload = false;
    };
  };
}
