{inputs, config, ...}: {
  flake-file.inputs.determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

  flake.darwinModules.determinate = {pkgs, lib, ...}: {
    imports = [inputs.determinate.darwinModules.default];
    determinateNix = {
      enable = true;
      customSettings = {
        # Mirror settings from nix.nix that nix-darwin no longer manages
        sandbox = false;
        trusted-users = ["root" "@admin"];
        allowed-users = ["@admin"];
        max-jobs = 8;
        cores = 0;
        trusted-substituters = config.flake.nixConfig.extra-substituters;
        trusted-public-keys = config.flake.nixConfig.extra-trusted-public-keys;
        connect-timeout = 5;
        fallback = true;
        log-lines = 25;
        download-buffer-size = 1073741824;
        nar-buffer-size = 134217728;
        max-free = 3145728000;
        min-free = 536870912;
        builders-use-substitutes = true;
      };
    };
  };

  flake.nixosModules.determinate = {
    imports = [inputs.determinate.nixosModules.default];
  };
}
