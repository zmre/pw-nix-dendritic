{
  flake.darwinModules.comms-gui = {
    homebrew.casks = [
      "discord"
      "proton-mail-bridge" # TODO: nix version now installs and works -- move over
      "proton-mail"
      "signal" # TODO: move to home-manager (signal-desktop) when not broken
      #"webex"
      "zoom" # TODO: move to home-manager (zoom-us)
    ];
    homebrew.masApps = {
      "Slack" = 803453959;
    };
  };

  flake.modules.homeManager.comms-gui = {
    pkgs,
    lib,
    ...
  }: {
    # Mail.app script menu is macOS-only
    home.file = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      "Library/Scripts/Applications/Mail/mail-app-copy-message-link.scpt".source = ../../../dotfiles/scripts/mail-app-copy-message-link-compiled.scpt;
    };
  };

  flake.nixosModules.comms-gui = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      slack
      discord
      element-desktop
    ];
  };
}
