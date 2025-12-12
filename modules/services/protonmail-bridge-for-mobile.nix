{
  flake.nixosModules.protonmail-bridge = {
    networking.firewall.allowedTCPPorts = [37027 1143 1025];
  };
  flake.modules.homeManager.protonmail-bridge = {
    pkgs,
    lib,
    ...
  }: let
    protonmail-bridge-open = pkgs.protonmail-bridge.overrideAttrs (old: {
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace utils/smtp-send/main.go --replace "127.0.0.1" "0.0.0.0"
          substituteInPlace internal/constants/constants.go --replace "127.0.0.1" "0.0.0.0"
          substituteInPlace utils/port-blocker/port-blocker.go --replace "127.0.0.1" "0.0.0.0"
          substituteInPlace internal/focus/service.go --replace "127.0.0.1" "0.0.0.0"
          substituteInPlace internal/frontend/grpc/service.go --replace "127.0.0.1" "0.0.0.0"
        '';
      # Need to launch protonmail-bridge --cli and run `cert import` to set things up the rest of the way
      # I use tailscale cert to generate certs. I pass in the .crt when it asks for a pem and all that works
    });

    # Proton requires a secret service and without a GUI, pass is the winner.
    # Pass requires gnupg and we have to have a running agent for it, but I couldn't make this
    # work right at a system level so need it to be a per-user thing, which sadly means that not only
    # do I need to be around to unlock the HD on boot, I need to log in to kick off protonmail-bridge
    dependentPackages = with pkgs; [
      libsecret
      pass
      pass-secret-service
      gnupg
      gpg-tui
      # pinentry-tty
    ];
  in {
    ## turns out both the nixos and the home-manager services are only triggered to start after a GUI starts
    ## and we aren't currently running a gui on this machine. so... gonna need to do this by hand;
    ## here are the settings that would work if we had a gui running:
    # services.protonmail-bridge.enable = true;
    # services.protonmail-bridge.package = protonmail-bridge-open;
    # services.protonmail-bridge.logLevel = "error"; # one of "panic", "fatal", "error", "warn", "info", "debug"
    # services.protonmail-bridge.extraPackages = with pkgs; [libsecret pass pass-secret-service];

    # programs.gnupg.agent.enable = true;
    # programs.gnupg.agent.pinentryPackage = pkgs.pinentry-tty;
    home.packages = dependentPackages ++ [protonmail-bridge-open];

    systemd.user.services.protonmail-bridge = {
      Unit = {
        Description = "ProtonMail Bridge";
      };

      Service = {
        Environment = ["PATH=${lib.makeBinPath dependentPackages}"];
        ExecStart = "${lib.getExe protonmail-bridge-open} --noninteractive --log-level error";
        Restart = "always";
      };

      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
}
