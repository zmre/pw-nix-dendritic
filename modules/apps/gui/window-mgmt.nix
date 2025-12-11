{inputs, ...}: {
  flake-file.inputs.pwaerospace.url = "github:zmre/aerospace-sketchybar-nix-lua-config";
  flake-file.inputs.pwaerospace.inputs.nixpkgs.follows = "nixpkgs";
  flake-file.inputs.pwaerospace.inputs.flake-utils.follows = "flake-utils";

  flake.nixosModules.window-mgmt = {pkgs, ...}: {
    services.displayManager.defaultSession = "none+i3";

    # Enable the X11 windowing system.
    services.xserver = {
      enable = true;
      autorun = true;
      defaultDepth = 24;
      xkb.options = "caps:escape";
      # Setup a graphical login
      displayManager = {
        lightdm.enable = true;
        sessionCommands = ''
          case $(hostname) in
            volantis)
              ${pkgs.xorg.xrandr}/bin/xrandr --newmode "3000x2000_60.00"  513.44  3000 3240 3568 4136  2000 2001 2004 2069  -HSync +Vsync
              ${pkgs.xorg.xrandr}/bin/xrandr --addmode eDP-1 "3000x2000_60.00"
              ${pkgs.xorg.xrandr}/bin/xrandr -s 3000x2000
              ;;
            *)
              echo unknown host
              ;;
          esac
        '';
      };
      # Keyboard
      xkb.layout = "us";
      autoRepeatDelay = 265;
      autoRepeatInterval = 20;
      windowManager.i3 = {
        enable = true;
        package = pkgs.stable.i3;
        extraPackages = with pkgs.stable; [
          rofi
          polybar
          feh
          lxappearance
          xclip
          picom
          i3status-rust
          i3lock
          i3blocks
        ];
      };
    };
    environment.systemPackages = with pkgs; [
      # wm support
      xss-lock
      syncthingtray-minimal
      arandr
      #i3-auto-layout # should change default split; not working

      # apps
      #spotify-qt
      nomacs
    ];
  };

  flake.darwinModules.window-mgmt = {pkgs, ...}: let
    inherit (pkgs.stdenvNoCC.hostPlatform) system;
    pwaerospace = inputs.pwaerospace.packages.${system}.default;
  in {
    homebrew.casks = [
      "default-folder-x"

      # quicklook plugins
      "qlmarkdown"
      "qlstephen"
      #"qlprettypatch" # not updated in 9 years
      "qlvideo"
      "raycast"

      # Following three things are for sketchybar
      "font-sf-pro"
      "font-sf-mono-for-powerline"
      "sf-symbols"

      "swiftdefaultappsprefpane"
      "tor-browser" # TODO: move to home-manager (tor-browser-bundle-bin) when it builds

      # Keeping the next three together as they act in concert and are made by the same guy
      "kindavim" # ctrl-esc allows you to control an input area as if in vim normal mode
      "scrolla" # use vim commands to select scroll areas and scroll
      "wooshy" # use cmd-shift-space to bring up search to select interface elements in current app
    ];
    environment.systemPackages = [
      pwaerospace
    ];
    # launchd = {
    #   # enable by default is true only on darwin
    #   agents = {
    #     "com.zmre.pwaerospace" = {
    #       command = "${pwaerospace}/bin/pwaerospace";
    #       serviceConfig = {
    #         Label = "com.zmre.pwaerospace";
    #         Program = "${pwaerospace}/bin/pwaerospace";
    #         RunAtLoad = true;
    #         KeepAlive = true;
    #       };
    #     };
    #   };
    # };
    system.defaults.CustomUserPreferences = {
      "mo.com.sleeplessmind.Wooshy" = {
        "KeyboardShortcuts_toggleWith" = "{\"carbonModifiers\":768,\"carbonKeyCode\":49}";
        SUEnableAutomaticChecks = 0;
        SUUpdateGroupIdentifier = 3425398139;
        allowCyclingThroughTargets = 1;
        "com_apple_SwiftUI_Settings_selectedTabIndex" = 4;
        fuzzyMatchingFlavor = "wooshyClassic";
        hazeOverWindowStyle = "fadeOutExceptDockMenuBarAndFrontmostApp";
        inputPosition = "aboveWindow";
        inputPreset = "custom";
        inputTextSize = 20;
        searchIncludesTrafficLightButtons = 1;
      };
      "mo.com.sleeplessmind.kindaVim" = {
        "KeyboardShortcuts_enterNormalMode" = "{\"carbonModifiers\":4096,\"carbonKeyCode\":53}";
        "NSStatusItem Preferred Position Item-0" = 6009;
        SUEnableAutomaticChecks = 0;
        SUUpdateGroupIdentifier = 790660886;
        appsForWhichToEnforceElectron = "[\"com.superhuman.electron\"]";
        appsForWhichToEnforceKeyboardStrategy = "[\"mo.com.sleeplessmind.Wooshy\"]";
        appsForWhichToUseHybridMode = "[\"com.apple.Safari\"]";
        appsToAdviseFor = "[\"com.apple.mail\"]";
        appsToIgnore = "[\"io.alacritty\",\"com.microsoft.VSCode\",\"org.qt-project.Qt.QtWebEngineCore\"]";
        charactersWindowContent = "move";
        "com_apple_SwiftUI_Settings_selectedTabIndex" = 0;
        enableCommandPassthrough = 1;
        enableOptionPassthrough = 1;
        enterNormalModeWith = "customShortcut";
        hazeOverWindowNonFullScreenOpacity = "0.5173477564102564";
        sendEscapeToMacOSWith = "commandEscape";
        showCharactersWindow = 0;
      };
      "mo.com.sleeplessmind.Scrolla" = {
        "KeyboardShortcuts_toggleWith" = "{\"carbonModifiers\":4352,\"carbonKeyCode\":49}";
        "NSStatusItem Preferred Position Item-0" = 6276;
        SUEnableAutomaticChecks = 0;
        SUUpdateGroupIdentifier = 3756402529;
        "com_apple_SwiftUI_Settings_selectedTabIndex" = 0;
        ignoreAreasWithoutScrollBars = 0;
      };
      "com.raycast.macos" = {
        NSNavLastRootDirectory = "~/src/scripts/raycast";
        "NSStatusItem Visible raycastIcon" = 0;
        commandsPreferencesExpandedItemIds = [
          "extension_noteplan-3__00cda425-a991-4e4e-8031-e5973b8b24f6"
          "builtin_package_navigation"
          "builtin_package_scriptCommands"
          "builtin_package_floatingNotes"
        ];
        "emojiPicker_skinTone" = "mediumLight";
        initialSpotlightHotkey = "Command-49";
        navigationCommandStyleIdentifierKey = "legacy";
        "onboarding_canShowActionPanelHint" = 0;
        "onboarding_canShowBackNavigationHint" = 0;
        "onboarding_completedTaskIdentifiers" = [
          "startWalkthrough"
          "calendar"
          "setHotkeyAndAlias"
          "snippets"
          "quicklinks"
          "installFirstExtension"
          "floatingNotes"
          "windowManagement"
          "calculator"
          "raycastShortcuts"
          "openActionPanel"
        ];
        organizationsPreferencesTabVisited = 1;
        popToRootTimeout = 60;
        raycastAPIOptions = 8;
        raycastGlobalHotkey = "Command-49";
        raycastPreferredWindowMode = "default";
        raycastShouldFollowSystemAppearance = 1;
        # presentation modes: 1=screen with active window, 2=primary screen
        raycastWindowPresentationMode = 2;
        showGettingStartedLink = 0;
        "store_termsAccepted" = 1;
        suggestedPreferredGoogleBrowser = 1;
      };
      "com.stclairsoft.DefaultFolderX5" = {
        SUEnableAutomaticChecks = 0;
        askedToLaunchAtLogin = 1;
        askedToRemoveV4 = 1;
        currentSet = "Default Set";
        finderClickDesktop = 1;
        openInFrontFinderWindow = 0;
        showDrawer = 0;
        showDrawerButton = 1;
        showMenuButton = 1;
        showStatusItem = 0;
        toolbarShowAttributesOnOpen = 1;
        toolbarShowAttributesOnSave = 1;
        transferredOldUsageData = 1;
        welcomeShown = 1;
      };
    };
  };

  flake.modules.homeManager.window-mgmt = {
    pkgs,
    config,
    lib,
    ...
  }: {
    home.file = {
      ".wallpaper.jpg".source = ../../../wallpaper/castle2.jpg;
      ".lockpaper.png".source = ../../../wallpaper/kali.png;
    };

    gtk = pkgs.lib.mkIf pkgs.stdenv.isLinux {
      enable = true;

      font = {
        name = "FiraCode Nerd Font";
        size = 9;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
        #name = "Breeze Dark";
        #package = pkgs.gnome-breeze;
      };
      theme = {
        package = pkgs.matcha-gtk-theme;
        name = "Matcha-dark-azul";
      };
    };
    services.dunst.enable = pkgs.stdenv.isLinux; # notification daemon
    # top bar
    services.polybar = rec {
      enable = pkgs.stdenv.isLinux;
      package = pkgs.polybar.override {
        # i3GapsSupport = true;
        pulseSupport = true;
      };
      script = "${package}/bin/polybar dracula &";
      settings = {
        "colors" = {
          background = {
            text = "#282a36";
            alt = "#282a36";
          };
          foreground = {
            text = "#f8f8f2";
            alt = "#f8f8f2";
          };
          #primary = "#13f01e";
          #secondary = "#bd93f9";
          #alert = "#bd93f9";
          alert = "\${self.red}";

          yellow = "#ffe74c";
          green = "#50fa7b";
          red = "#ff5964";
          blue = "#35a7ff";
          navy = "#38618c";
          purple = "#f18cfa";
          orange = "#ffb86c";
          border = "#44465a";
          darkgray = "#282a36";
          white = "#f8f8f2";
        };
        "bar/dracula" = {
          #monitor = "DisplayPort-2";
          height = 28;
          enable.ipc = true;
          background = "\${colors.background}";
          foreground = "\${colors.foreground}";
          line.size = 3;
          border = {
            #color = "#44465a";
            color = "\${colors.border}";
            bottom.size = 3;
          };
          padding = {
            left = 0;
            right = 2;
          };
          module.margin = {
            left = 1;
            right = 2;
          };
          font = [
            "FiraCode Nerd Font:pixelsize=12;1"
            #"Source Code Pro:pixelsize=12;1"
            #"Font Awesome 5 Free Solid:size=11;1"
            #"Font Awesome 5 Free Solid:size=10;1"
            #"Font Awesome 5 Brands Regular:size=11;1"
          ];
          modules = {
            left = "cpu memory temperature";
            center = "date";
            right = "wireless-network battery backlight pulseaudio powermenu";
          };
          cursor = {
            click = "pointer";
            scroll = "ns-resize";
          };
        };
        "module/battery" = {
          type = "internal/battery";
          battery = "BAT1";
          adapter = "ACAD";
          full-at = 98;
          label-charging = "%percentage%%";
          label-discharging = "%percentage%%";
          label-full = "Full";
          format = {
            text = "<label-full>";
            full = {
              prefix = {
                text = " ";
                foreground = "\${colors.green}";
              };
            };
            charging = {
              text = "<label-charging>";
              prefix = {text = " ";};
            };
            discharging = {
              # 
              text = "<ramp-capacity> <label-discharging>";
            };
          };
          ramp-capacity-0 = ""; # 10
          ramp-capacity-0-foreground = "\${colors.alert}";
          ramp-capacity-1 = ""; # 20
          ramp-capacity-1-foreground = "\${colors.alert}";
          ramp-capacity-2 = ""; # 30
          ramp-capacity-3 = ""; # 40
          ramp-capacity-4 = ""; # 50
          ramp-capacity-5 = ""; # 60
          ramp-capacity-6 = ""; # 70
          ramp-capacity-7 = ""; # 80
          ramp-capacity-8 = ""; # 90
          ramp-capacity-9 = "";
          ramp-capacity-9-foreground = "\${colors.green}";
        };
        "module/backlight" = {
          type = "internal/backlight";
          card = "intel_backlight";
          use-actual-brightness = true;
          label = "%percentage%%";
          format = {
            text = "<label>";
            prefix = {
              text = " ";
              foreground = "\${colors.yellow}";
            };
          };
        };
        "module/wireless-network" = {
          type = "internal/network";
          interface = "wlan0";
          #format-connected = "<label-connected>";
          format-disconnected = "<label-disconnected>";
          format-packetloss = {
            text = "<animation-packetloss> <label-connected>";
            foreground = "\${colors.alert}";
          };
          label-disconnected = "睊";
          format = {
            connected = {
              text = "<label-connected>";
              prefix = {
                text = "  ";
                foreground = "\${colors.purple}";
              };
            };
          };
          label-connected = "%essid% %signal%%";
        };
        "module/xkeyboard" = {
          type = "internal/xkeyboard";
          blacklist = ["num lock"];
          format = {
            text = "<label-layout><label-indicator>";
            spacing = 0;
            prefix = {
              text = " ";
              foreground = "\${colors.orange}";
            };
          };
          label = {
            layout = "%layout%";
            indicator.on = " %name%";
          };
        };
        "module/cpu" = {
          type = "internal/cpu";
          format = "<label> <ramp-coreload>";
          label = " %percentage%%";
          ramp-coreload-spacing = 1;
          ramp-coreload-0 = "▁";
          ramp-coreload-1 = "▂";
          ramp-coreload-2 = "▃";
          ramp-coreload-3 = "▄";
          ramp-coreload-4 = "▅";
          ramp-coreload-4-foreground = "\${colors.yellow}";
          ramp-coreload-5 = "▆";
          ramp-coreload-5-foreground = "\${colors.yellow}";
          ramp-coreload-6 = "▇";
          ramp-coreload-6-foreground = "\${colors.alert}";
          ramp-coreload-7 = "█";
          ramp-coreload-7-foreground = "\${colors.alert}";
        };
        "module/memory" = {
          type = "internal/memory";
          interval = 3;
          format = "<label> <bar-used>";
          label = " %gb_used%";
          bar-used-width = 30;
          bar-used-indicator = "";
          bar-used-foreground-0 = "\${colors.green}";
          bar-used-foreground-1 = "#557755";
          bar-used-foreground-2 = "\${colors.yellow}";
          bar-used-foreground-3 = "\${colors.alert}";
          bar-used-fill = "▐";
          bar-used-empty = "▐";
          bar-used-empty-foreground = "#444444";
        };
        "module/temperature" = {
          type = "internal/temperature";
          interval = 10;
          hwmon-path = "/sys/devices/platform/coretemp.0/hwmon/hwmon4/temp1_input";
          base-temperature = 20; # celsius
          warn-temperature = 60;
          units = true;
          format = "<ramp> <label>";
          format-warn = "<ramp> <label-warn>";
          label = "%temperature-f%";
          label-warn = "%temperature-f%";
          label-warn-foreground = "\${colors.alert}";
          ramp-0 = "";
          ramp-1 = "";
          ramp-2 = "";
          ramp-foreground = "\${colors.yellow}";
        };
        "module/date" = {
          type = "internal/date";
          interval = 5;
          date = {
            text = "";
            alt = " %m/%d/%y";
          };
          time = {
            text = " %I:%M %P ";
            alt = " %I:%M %P";
          };
          format = {
            prefix.foreground = "\${colors.foreground-alt}";
            padding = 0.5;
          };
          label = "%date% %time%";
        };
        "module/pulseaudio" = {
          type = "internal/pulseaudio";
          format-volume = "<ramp-volume> <label-volume>";
          ramp-volume-0 = "奄";
          ramp-volume-0-foreground = "\${colors.blue}";
          ramp-volume-1 = "奔";
          ramp-volume-1-foreground = "\${colors.blue}";
          ramp-volume-2 = "墳";
          ramp-volume-2-foreground = "\${colors.blue}";
          ramp-volume-3 = " ";
          ramp-volume-3-foreground = "\${colors.blue}";

          label = {
            volume = "%percentage%";
            muted = {
              text = "婢";
              foreground = "\${colors.blue}";
            };
          };
        };
        "module/powermenu" = {
          type = "custom/menu";
          expand.right = true;
          format.spacing = 1;
          label = {
            open = {
              text = "%{T3}";
              foreground = "\${colors.navy}";
            };
            close = {
              text = "%{T2}";
              foreground = "\${colors.red}";
            };
            separator = {
              text = "|";
              foreground = "\${colors.foreground-alt}";
            };
          };
          menu = [
            [
              {
                text = "%{T3} ";
                exec = "menu-open-1";
              }
              {
                text = "%{T3}";
                exec = "menu-open-2";
              }
            ]
            [
              {
                text = "%{T2}";
                exec = "menu-open-0";
              }
              {
                text = "%{T3} ";
                exec = "sudo ${pkgs.systemd}/bin/reboot now";
              }
            ]
            [
              {
                text = "%{T3}";
                exec = "sudo ${pkgs.systemd}/bin/poweroff";
              }
              {
                text = "%{T2}";
                exec = "menu-open-0";
              }
            ]
          ];
        };
        "settings" = {screenchange.reload = true;};
        "wm" = {
          margin = {
            top = 5;
            bottom = 5;
          };
        };
      };
    };
    services.playerctld.enable = pkgs.stdenv.isLinux;
    #services.spotifyd.enable = true;

    services.picom.enable = pkgs.stdenv.isLinux; # xsession compositor
    xsession.windowManager.i3.enable = pkgs.stdenv.isLinux;
    xsession.windowManager.i3.config = {
      terminal = "${pkgs.alacritty}/bin/alacritty";
      modifier = "Mod4";
      menu = ''"${pkgs.rofi}/bin/rofi -modi drun -show drun -theme glue_pro_blue"'';
      # need to use i3-gaps package to use these
      gaps.inner = 4;
      gaps.outer = 2;
      gaps.smartBorders = "on";
      gaps.smartGaps = true;
      fonts = {
        names = ["pango:SauceCodePro Nerd Font"];
        size = 6.0;
      };
      focus.newWindow = "focus";
      focus.followMouse = false;
      window.border = 3;
      colors.focused = {
        background = "#285577";
        border = "#4c7899";
        childBorder = "#285577";
        indicator = "#2e9ef4";
        text = "#ffffff";
      };
      keybindings = let
        mod = config.xsession.windowManager.i3.config.modifier;
        refresh = "killall -SIGUSR1 i3status-rs";
      in
        lib.mkOptionDefault {
          "${mod}+Return" = "exec alacritty";
          "${mod}+j" = "focus left";
          "${mod}+k" = "focus down";
          "${mod}+l" = "focus up";
          "${mod}+Tab" = ''
            exec --no-startup-id "${pkgs.rofi}/bin/rofi -modi drun -show window -theme iggy"'';
          "${mod}+semicolon" = "focus right";
          "${mod}+Shift+j" = "move left";
          "${mod}+Shift+k" = "move down";
          "${mod}+Shift+l" = "move up";
          "${mod}+Shift+semicolon" = "move right";
          "${mod}+h" = "split h";
          "${mod}+v" = "split v";
          "${mod}+t" = "layout tabbed";
          "${mod}+s" = "layout stacking";
          "${mod}+w" = "layout default";
          "${mod}+e" = "layout toggle split tabbed stacking splitv splith";
          "${mod}+m" = "move scratchpad";
          "${mod}+o" = "scratchpad show";
          "${mod}+p" = "floating toggle";
          "${mod}+Shift+p" = ''[class="KeePassXC"] scratchpad show'';
          "${mod}+x" = "move workspace to output next";
          "${mod}+Ctrl+Right" = "workspace next";
          "${mod}+Ctrl+Left" = "workspace prev";
          "${mod}+F9" = "exec i3lock --nofork -i ~/.lockpaper.png";
          # Use pactl to adjust volume in PulseAudio.
          "XF86AudioRaiseVolume" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5% && ${refresh}";
          "XF86AudioLowerVolume" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5% && ${refresh}";
          "XF86AudioMute" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle && ${refresh}";
          "XF86AudioMicMute" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle && ${refresh}";
          "XF86AudioPlay" = "exec ${pkgs.playerctl}/bin/playerctl play";
          "XF86AudioPause" = "exec ${pkgs.playerctl}/bin/playerctl pause";
          "XF86AudioNext" = "exec ${pkgs.playerctl}/bin/playerctl next";
          "XF86AudioPrev" = "exec ${pkgs.playerctl}/bin/playerctl prev";
          # backlight
          "XF86MonBrightnessUp" = "exec --no-startup-id ${pkgs.light}/bin/light -A 1";
          "XF86MonBrightnessDown" = "exec --no-startup-id ${pkgs.light}/bin/light -U 1";
        };
      defaultWorkspace = "workspace number 1";
      assigns = {
        "1: term" = [{class = "^Alacritty$";}];
        "2: web" = [{class = "^(Firefox|qutebrowser)$";}];
      };
      modes = {
        resize = {
          Down = "resize grow height 10 px or 10 ppt";
          Left = "resize shrink width 10 px or 10 ppt";
          Right = "resize grow width 10 px or 10 ppt";
          Up = "resize shrink height 10 px or 10 ppt";
          k = "resize grow height 10 px or 10 ppt";
          j = "resize shrink width 10 px or 10 ppt";
          semicolon = "resize grow width 10 px or 10 ppt";
          l = "resize shrink height 10 px or 10 ppt";
          Escape = "mode default";
          Return = "mode default";
        };
      };
      #bars.status_command = "i3status-rs";
      #bar.i3bar_command = "";
      #bars.workspace_buttons = true;
      #bars.strip_workspace_numbers = false;
      startup = [
        {
          command = "systemctl --user restart polybar";
          always = true;
          notification = false;
        }
        {
          command = "systemctl --user restart syncthing";
          always = true;
          notification = false;
        }
        {
          command = "feh --bg-fill ~/.wallpaper.jpg";
          always = true;
          notification = false;
        }
        # NetworkManager is the most popular way to manage wireless networks on Linux,
        # and nm-applet is a desktop environment-independent system tray GUI for it.
        {
          command = "nm-applet";
          notification = false;
        }
        {
          command = "syncthingtray";
          always = true;
          notification = false;
        }
        {
          command = "blueman-tray";
          always = true;
          notification = false;
        }
        {command = "qutebrowser";}
        {command = "alacritty";}
        {
          command = "keepassxc";
          always = true;
        }
      ];
    };
    # xss-lock grabs a logind suspend inhibit lock and will use i3lock to lock the
    # screen before suspend. Use loginctl lock-session to lock your screen.
    xsession.windowManager.i3.extraConfig = ''
      default_orientation auto
      exec --no-startup-id xss-lock --transfer-sleep-lock -- i3lock --nofork -i ~/.lockpaper.png
      exec_always --no-startup-id i3-auto-layout
      for_window [title="Chooser"] floating enable
      for_window [class="KeePassXC"] move scratchpad
    '';
    programs.i3status-rust.enable = pkgs.stdenv.isLinux;
    programs.i3status-rust.bars = {
      bottom = {
        blocks = [
          {
            block = "disk_space";
            path = "/";
            alias = "/";
            info_type = "available";
            unit = "GB";
            interval = 60;
            warning = 20.0;
            alert = 10.0;
          }
          {
            block = "memory";
            display_type = "memory";
            format_mem = "{mem_used_percents}";
            format_swap = "{swap_used_percents}";
          }
          {
            block = "cpu";
            interval = 1;
          }
          {
            block = "load";
            interval = 1;
            format = "{1m}";
          }
          {block = "sound";}
          {
            block = "time";
            interval = 60;
            format = "%a %d/%m %R";
          }
        ];
        settings = {
          theme = {
            name = "solarized-dark";
            overrides = {
              idle_bg = "#123456";
              idle_fg = "#abcdef";
            };
          };
        };
        icons = "awesome5";
        theme = "gruvbox-dark";
      };
    };
  };
}
