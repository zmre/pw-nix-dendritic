{config, inputs, ...}: {
  flake-file.inputs.determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

  flake.darwinModules.determinate = {pkgs, lib, ...}: {
    imports = [inputs.determinate.darwinModules.default];

    determinateNix.enable = true;

    # Determinate Nix manages its own daemon, GC, and package;
    # override nix.* settings from the shared "system" module (nix.nix)
    # that would conflict with nix.enable = false.
    nix.gc.automatic = lib.mkForce false;
    nix.channel.enable = lib.mkForce false;

    determinateNix.customSettings = {
      # Declared typed options (must match exact types)
      trusted-users = ["root" "@admin"];
      cores = 0;

      # Freeform settings (atom or list of atoms)
      allowed-users = ["@admin"];
      max-jobs = 8;
      substituters = config.flake.nixConfig.extra-substituters;
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

    # Remote builders via the determinate module's buildMachines option
    determinateNix.distributedBuilds = true;
    determinateNix.buildMachines = [
      {
        hostName = "avalon";
        systems = ["x86_64-linux" "aarch64-linux"];
        maxJobs = 8;
        speedFactor = 2;
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      }
    ];
  };
}
