{
  config,
  inputs,
  ...
}: let
  common = {pkgs, ...}: {
    imports = [inputs.home-manager.nixosModules.default];
    time.timeZone = "America/Denver";

    # environment setup
    environment = {
      ${
        if pkgs.stdenv.isLinux
        then "sessionVariables"
        else "variables"
      } = {
        LANGUAGE = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
      };
      etc = {
        home-manager.source = "${inputs.home-manager}";
        nixpkgs-unstable.source = "${inputs.nixpkgs-unstable}";
        nixpkgs-stable.source =
          if pkgs.stdenvNoCC.isDarwin
          then "${inputs.nixpkgs-stable-darwin}"
          else "${inputs.nixpkgs-stable}";
      };

      # list of acceptable shells in /etc/shells
      shells = with pkgs.stable; [bash zsh];
      pathsToLink = ["/libexec" "/share/zsh"];
    };
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      enableBashCompletion = true;
    };
    nix = {
      # package = pkgs.stable.nix;
      settings = {
        # Because macos sandbox can create issues https://github.com/NixOS/nix/issues/4119
        sandbox = false; # !pkgs.stdenv.isDarwin;
        trusted-users = ["root" "@admin" "@wheel"];

        # TODO: turn this back on
        # disabled 2023-01-21 because of "cannot link" errors as described here:
        # https://github.com/NixOS/nix/issues/7273
        # issue still open 2025-11-28
        auto-optimise-store = false;
        max-jobs = 8;
        cores = 0; # use them all
        allowed-users = ["@wheel"];
      };

      #optimise.automatic = true;
      gc = {
        automatic = true;
        options = "--delete-older-than 30d";
      };
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
