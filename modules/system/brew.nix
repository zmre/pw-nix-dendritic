{inputs, ...}: {
  flake-file.inputs = {
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-freetube = {
      url = "github:pikachuexe/homebrew-freetube";
      flake = false;
    };
  };

  flake.darwinModules.brew = {config, ...}: let
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "pikachuexe/homebrew-freetube" = inputs.homebrew-freetube; # note: always name things with "homebrew-" prefix in attr name. this is normally pikachuexe/freetube, but adding the homebrew- fixes errors
    };
  in {
    imports = [inputs.nix-homebrew.darwinModules.nix-homebrew];
    nix-homebrew = {
      # Install Homebrew under the default prefix
      enable = true;

      # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
      enableRosetta = false;

      # User owning the Homebrew prefix
      user = config.system.primaryUser;

      # Optional: Declarative tap management
      inherit taps;

      # Optional: Enable fully-declarative tap management
      #
      # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
      mutableTaps = false;
    };
    homebrew = {
      enable = true;
      greedyCasks = true;
      caskArgs.no_quarantine = true;
      user = config.system.primaryUser;
      onActivation = {
        autoUpdate = false;
        upgrade = true;
        cleanup = "uninstall"; # should maybe be "zap" - remove anything not listed here
      };
      global = {
        brewfile = true;
        autoUpdate = false;
      };
      taps = builtins.attrNames taps;
      casks = [
        # TODO: move these into better places; this file should just setup homebrew system
        "elgato-stream-deck"
        "istat-menus"
        "karabiner-elements"
        "kopiaui" # ui for kopia dedupe backup
        "league-of-legends"
        "marked-app"
        "parallels"
        "zotero" # TODO: move to home-manager?
      ];

      masApps = {
        # TODO: move these into better places; this file should just setup homebrew system
        "Amphetamine" = 937984704;
        #"Blurred" = 1497527363; # dim non-foreground windows -- removed when I realized this is Intel not ARM :-(
        "Blackmagic Disk Speed Test" = 425264550;
        #"Boxy SVG" = 611658502; # nice code-oriented visual svg editor
        "Brother iPrint&Scan" = 1193539993;
        "Cardhop" = 1290358394; # contacts alternative
        #"Drafts" = 1435957248;
        "Fantastical" = 975937182; # calendar alternative
        "Forecast Bar" = 982710545;
        #"Ghostery – Privacy Ad Blocker" = 1436953057; # old version
        "iA Writer" = 775737590;
        #"Ice Cubes" = 6444915884; # mastodon client -- it's good but i switched to ivory
        "iMovie" = 408981434;
        #"iStumbler" = 546033581;
        "Ivory" = 6444602274;
        "Keynote" = 409183694;
        "Keyshape" = 1223341056; # animated svg editor
        "Microsoft Excel" = 462058435;
        "Microsoft Word" = 462054704;
        "Microsoft PowerPoint" = 462062816;
        "Monodraw" = 920404675; # ASCII drawings
        #"MsgFiler" = 6478043112; # Mail extension (sort of) for keyboard driven message filing
        #"NextDNS" = 1464122853;
        #"NotePlan" = 1505432629;
        "Numbers" = 409203825;
        "Pages" = 409201541;
        "PCalc" = 403504866;
        #"PeakHour" = 1560576252;
        "Scrivener" = 1310686187;
        #"SQLPro Studio" = 985614903;
        #"StopTheMadness" = 1376402589;
        # app store sandbox version doesn't allow some features like ssh
        #"Tailscale" = 1475387142; # P2P mesh VPN for my devices
        #"WireGuard" = 1451685025; # VPN -- but tailscale does it all for me now
      };
      brews = [
        # TODO: move these into better places; this file should just setup homebrew system
        "ansiweather"
        "brightness"
        "ca-certificates"
        "choose-gui"
        "ddcctl"
        "ical-buddy"
      ];
    };
  };
}
