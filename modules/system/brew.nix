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
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-services = {
      url = "github:homebrew/homebrew-services";
      flake = false;
    };
  };

  flake.darwinModules.brew = {config, ...}: let
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
      "homebrew/homebrew-services" = inputs.homebrew-services;
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
      taps = taps;

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
        #"amethyst" # for window tiling -- I miss chunkwm but it's successor, yabai, was unstable for me and required security compromises.
        #"audio-hijack" # used to use this for making my audio cleaner, but removed when I got a fancy audio setup. bringing back now (2024-07-11) to experiment with recording of sources
        # {
        # Replacing with open source ice bar 2024-11-29
        #   name = "bartender"; # organize status bar
        #   greedy = true;
        # }
        # {
        #   name = "bettertouchtool";
        #   greedy = true;
        # }
        # Decided against Calibre since it doesn't do audio books and copies
        # all books it finds into its own folder, which I couldn't stop
        # Need an alternate option
        #"canon-eos-utility"
        "discord"
        #"docker" # removed in favor of colima + docker cli
        "dropbox"
        "elgato-stream-deck"
        # {
        #   name = "focusrite-control-2";
        #   greedy = true;
        # }

        "ghostty" # available in nixos only for linux
        "google-drive"
        # {
        #   name = "gotomeeting";
        #   greedy = true;
        # }
        #"handbrake-app" # just temporary 2025-08-08
        #"httpie"
        "istat-menus"
        "karabiner-elements"
        #"jordanbaird-ice" # icebar alternative to bartender https://github.com/jordanbaird/Ice
        #"kitty" # would prefer to let nix install this as I have for over a year but post 15.1, nix version doesn't launch right
        "kopiaui" # ui for kopia dedupe backup
        "league-of-legends"
        #"lm-studio"
        #"loopback" -- haven't been using this of late
        "marked-app"
        #"microsoft-office" -- moved this to apple app store
        # alphebetized under mpv
        # {
        #   name = "obs"; # TODO: move to nix version obs-studio when not broken
        #   greedy = true;
        # }
        "parallels"
        "proton-drive"
        "proton-mail-bridge" # TODO: nix version now installs and works -- move over
        "proton-mail"
        # "qutebrowser" # TODO: move over when it builds on arm64 darwin
        # Update: qutebrowser built today, 2023-09-07! but errors on launch :(
        #"quicklookase" # not updated in 6 years
        #"ripcord" # native (non-electron) desktop client for Slack + Discord -- try again in 2023
        # rode-central no longer works with the rodecaster video. for that, you need the "rodecaster app" which now, months after release, still isn't in brew :-(
        # currently needs to be installed manually
        # TODO: see if rodecaster-app gets added to homebrew
        # {
        #   name = "rode-central";
        #   greedy = true;
        # }

        "signal" # TODO: move to home-manager (signal-desktop) when not broken
        "sync"
        "tailscale-app" # moved from darwin services cuz exit nodes https://tailscale.com/kb/1065/macos-variants#comparison-table
        "transmission"
        #"transmit" # for syncing folders with dropbox on-demand instead of using their broken software
        "zoom" # TODO: move to home-manager (zoom-us)
        "zotero" # TODO: move to home-manager?
        # would be better to load these in a security shell, but nix versions don't build on mac
        # moving zed to home-manager 2025-05-12
        #"zed" # visual studio alternative in beta now; written in rust, uses gpu and multithreads to be smokin fast
        #"warp" # 2022-11-10 testing some crazy new rust-based terminal
        "webex"

        "wezterm"
      ];

      masApps = {
        "Amphetamine" = 937984704;
        #"Blurred" = 1497527363; # dim non-foreground windows -- removed when I realized this is Intel not ARM :-(
        "Blackmagic Disk Speed Test" = 425264550;
        #"Boxy SVG" = 611658502; # nice code-oriented visual svg editor
        "Brother iPrint&Scan" = 1193539993;
        "Cardhop" = 1290358394; # contacts alternative
        "DaisyDisk" = 411643860;
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
        "Slack" = 803453959;
        #"SQLPro Studio" = 985614903;
        #"StopTheMadness" = 1376402589;
        # app store sandbox version doesn't allow some features like ssh
        #"Tailscale" = 1475387142; # P2P mesh VPN for my devices
        #"WireGuard" = 1451685025; # VPN -- but tailscale does it all for me now
      };
      brews = [
        "ansiweather"
        "brightness"
        "ca-certificates"
        "choose-gui"
        "ddcctl"
        "ical-buddy"
        #"whisper-cpp"
        #"whisperkit-cli"
        # would rather load these as part of a security shell, but...
        "yt-dlp" # youtube downloader / 2024-11-19 moved back to nix now that curl-cffi (curl-impersonate) is supported
        "zstd" # needed for yt-dlp curl-impersonate
        "nghttp2" # needed for yt-dlp curl-impersonate
        # 2025-04-09 I'm getting errors saying curl-cffi is unavailable even though the nix recipe has it
        # so I'm adding it in both places for now
      ];
    };
  };
}
