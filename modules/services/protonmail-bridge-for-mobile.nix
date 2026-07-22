{
  flake.nixosModules.protonmail-bridge = {
    # The bridge is patched to bind 0.0.0.0, so restrict exposure to the
    # tailscale interface only (mobile clients reach it over the tailnet).
    # 1143 = IMAP, 1025 = SMTP. 37027 is bridge's local event/gRPC port and
    # does not need to be reachable remotely.
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [1143 1025];
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
    });

    # --- TLS certificate handling -------------------------------------------
    #
    # Mobile mail clients (iOS Mail, etc.) reject the bridge's default
    # self-signed cert with "tls: unknown certificate". We instead present a
    # publicly-trusted Let's Encrypt cert for this host's tailnet FQDN, issued
    # by `tailscale cert`, so clients validate it with no manual trust step.
    #
    # KEY MECHANISM: `cert import` in the bridge CLI stores the *path* to the
    # PEM files in its vault (vault.Certs.CustomCertPath/CustomKeyPath), and the
    # bridge re-reads that file every time it starts its TLS listeners. So the
    # interactive import only has to happen ONCE. After that, renewing is just
    # "overwrite the files in place + restart the service" -- which is exactly
    # what the timer below automates.
    #
    # ONE-TIME BOOTSTRAP (run once, by hand, while logged in so the vault is
    # unlocked via pass/gnupg):
    #
    #   mkdir -p ~/.config/protonmail/bridge-tls
    #   protonmail-bridge-cert-renew          # writes cert.pem/key.pem
    #   systemctl --user stop protonmail-bridge   # release single-instance lock
    #   protonmail-bridge --cli
    #     >>> cert import
    #     Enter the path to the cert.pem file: /home/pwalsh/.config/protonmail/bridge-tls/cert.pem
    #     Enter the path to the key.pem file:  /home/pwalsh/.config/protonmail/bridge-tls/key.pem
    #     >>> exit
    #   systemctl --user start protonmail-bridge
    #
    # (The "another instance is running" error you hit is exactly the
    # single-instance lock -- you must stop the service before `--cli`.)
    #
    # From then on, the protonmail-bridge-cert.timer keeps the cert fresh.

    protonmail-bridge-cert-renew = pkgs.writeShellApplication {
      name = "protonmail-bridge-cert-renew";
      runtimeInputs = with pkgs; [tailscale jq systemd coreutils];
      text = ''
        set -euo pipefail

        # Derive this host's tailnet FQDN (strip trailing dot).
        domain="$(tailscale status --json | jq -r '.Self.DNSName' | sed 's/\.$//')"
        if [ -z "$domain" ] || [ "$domain" = "null" ]; then
          echo "Could not determine tailnet FQDN; is tailscale up?" >&2
          exit 1
        fi

        cert_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/protonmail/bridge-tls"
        cert="$cert_dir/cert.pem"
        key="$cert_dir/key.pem"
        mkdir -p "$cert_dir"

        before=""
        [ -f "$cert" ] && before="$(sha256sum "$cert" | cut -d' ' -f1)"

        # tailscale re-issues via ACME only when near expiry; otherwise it
        # rewrites the cached cert. Cheap to run frequently.
        tailscale cert --cert-file "$cert" --key-file "$key" "$domain"

        after="$(sha256sum "$cert" | cut -d' ' -f1)"

        if [ "$before" != "$after" ]; then
          echo "Certificate changed; restarting protonmail-bridge"
          systemctl --user restart protonmail-bridge
        else
          echo "Certificate unchanged; no restart needed"
        fi
      '';
    };

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
    home.packages = dependentPackages ++ [protonmail-bridge-open protonmail-bridge-cert-renew];

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

    # Renew the tailscale-issued TLS cert and restart the bridge if it changed.
    # After the one-time `cert import` (see comment above), this is all that's
    # needed to keep mobile clients happy across cert expiries.
    systemd.user.services.protonmail-bridge-cert = {
      Unit = {
        Description = "Renew ProtonMail Bridge TLS certificate from Tailscale";
        After = ["network-online.target" "tailscaled.service"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe protonmail-bridge-cert-renew;
      };
    };

    systemd.user.timers.protonmail-bridge-cert = {
      Unit = {
        Description = "Weekly ProtonMail Bridge TLS certificate renewal";
      };
      Timer = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
      Install = {
        WantedBy = ["timers.target"];
      };
    };
  };
}
