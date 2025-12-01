{
  flake.darwinModules.comms-gui = {
    homebrew.casks = [
      "discord"
      "proton-mail-bridge" # TODO: nix version now installs and works -- move over
      "proton-mail"
      "signal" # TODO: move to home-manager (signal-desktop) when not broken
      "webex"
      "zoom" # TODO: move to home-manager (zoom-us)
    ];
    homebrew.masApps = {
      "Slack" = 803453959;
    };
  };
}
