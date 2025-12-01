{config, ...}: let
  common = {
    nix = {
      # package = pkgs.stable.nix;
      settings = {
        # Because macos sandbox can create issues https://github.com/NixOS/nix/issues/4119
        sandbox = false; # !pkgs.stdenv.isDarwin;
        # wheel for linux, admin for darwin
        trusted-users = ["root" "@admin" "@wheel" "${config.system.primaryUser}"];

        # TODO: turn this back on
        # disabled 2023-01-21 because of "cannot link" errors as described here:
        # https://github.com/NixOS/nix/issues/7273
        # issue still open 2025-11-28
        auto-optimise-store = false;

        max-jobs = 8;
        cores = 0; # use them all

        # wheel for linux, admin for darwin
        allowed-users = ["@wheel" "@admin"];

        trusted-substituters = config.flake.nixConfig.extra-substituters;
        trusted-public-keys = config.flake.nixConfig.extra-trusted-public-keys;

        # Fallback quickly if substituters are not available.
        connect-timeout = 5;
        fallback = true;

        # Enable flakes
        experimental-features = [
          "nix-command"
          "flakes"
          #"repl-flake"
        ];

        # The default at 10 is rarely enough.
        log-lines = 25;

        # Avoid disk full issues
        max-free = 3000 * 1024 * 1024;
        min-free = 512 * 1024 * 1024;

        # Avoid copying unnecessary stuff over SSH
        builders-use-substitutes = true;
      };

      #optimise.automatic = true;
      gc = {
        automatic = true;
        options = "--delete-older-than 30d";
      };

      # Disable nix channels. Use flakes instead.
      channel.enable = false;
    };
  };
in {
  flake.darwinModules.system = {
    imports = [common];
  };
  flake.nixosModules.system = {
    imports = [common];
  };
}
