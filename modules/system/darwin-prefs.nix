{
  flake.darwinModules.prefs = {config, ...}: {
    system.defaults = {
      # file viewer settings
      finder = {
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        QuitMenuItem = true;
        _FXShowPosixPathInTitle = true;
        # Use list view in all Finder windows by default
        FXPreferredViewStyle = "Nlsv";
        ShowPathbar = true;
        ShowStatusBar = true;
      };

      # if using spaces, below should be false
      # if using workspaces from aerospace, set below to true
      # Aerospace says mac is more stable with below true:
      # https://nikitabobko.github.io/AeroSpace/guide#a-note-on-displays-have-separate-spaces
      spaces.spans-displays = true; # separate spaces on each display

      # dock settings
      dock = {
        # auto show and hide dock
        autohide = true;
        # remove delay for showing dock
        autohide-delay = 0.0;
        # how fast is the dock showing animation
        autohide-time-modifier = 0.2;
        expose-animation-duration = 0.2;
        tilesize = 48;
        launchanim = false;
        static-only = false;
        showhidden = true;
        show-recents = false;
        show-process-indicators = true;
        orientation = "bottom";
        mru-spaces = false;
        expose-group-apps = true;
        # Hot corners
        # Possible values:
        #  0: no-op
        #  2: Mission Control
        #  3: Show application windows
        #  4: Desktop
        #  5: Start screen saver
        #  6: Disable screen saver
        #  7: Dashboard
        # 10: Put display to sleep
        # 11: Launchpad
        # 12: Notification Center
        # 13: Lock Screen
        # mouse in top right corner will (5) start screensaver
        wvous-tr-corner = 5;
      };

      # universalaccess = {
      # get rid of extra transparency in menu bar and elsewhere
      # reduceTransparency = false;
      # };

      NSGlobalDomain = {
        # Disable window animations to make Aerospace snappier
        NSAutomaticWindowAnimationsEnabled = false;
        # 2 = heavy font smoothing; if text looks blurry, back this down to 1
        AppleShowAllExtensions = true;
        # Dark mode
        AppleInterfaceStyle = "Dark";
        # auto switch between light/dark mode
        AppleInterfaceStyleSwitchesAutomatically = false;
        "com.apple.sound.beep.feedback" = 1;
        "com.apple.sound.beep.volume" = 0.606531; # 50%
        "com.apple.mouse.tapBehavior" = 1; # tap to click
        AppleTemperatureUnit = "Fahrenheit";
        AppleMeasurementUnits = "Inches";
        AppleShowScrollBars = "Automatic";
        NSScrollAnimationEnabled = true; # smooth scrolling
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        # no automatic smart quotes
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        NSDocumentSaveNewDocumentsToCloud = false;
        # speed up animation on open/save boxes (default:0.2)
        NSWindowResizeTime = 0.001;
        # when the below is on, it means you can hold cmd+ctrl and click anywhere on a window to drag it around
        NSWindowShouldDragOnGesture = true;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
      };
      CustomSystemPreferences = {
        #NSGlobalDomain = {
        #NSUserKeyEquivalents = {
        # @ is command
        # ^ is control
        # ~ is option
        # $ is shift
        # It seems this is the old place for putting global system shortcuts
        # The new place is the inscrutable com.apple.symbolichotkeys
        # which doesn't have nice syntax and uses numbers to represent operations
        # Are those numbers consistent across OS versions? Who knows!
        # Doing a `defaults read com.apple.symbolichotkeys` before and after changes
        # and diffing them seems to be the best way to reverse engineer things
        # and not a great option.
        #};
        #};
      };
      CustomUserPreferences = {
        NSGlobalDomain = {
          # Add a context menu item for showing the Web Inspector in web views
          WebKitDeveloperExtras = true;
          AppleMiniaturizeOnDoubleClick = false;
          NSAutomaticTextCompletionEnabled = true;
          # The menu bar at the top of the screen can be hidden all the time (shows up with your cursor at the top) with value 1;
          # normal operation showing all the time except in full screen is value of 0.
          _HIHideMenuBar = 1;
          "com.apple.sound.beep.flash" = false;
        };
        "com.apple.finder" = {
          OpenWindowForNewRemovableDisk = true;
          ShowExternalHardDrivesOnDesktop = true;
          ShowHardDrivesOnDesktop = true;
          ShowMountedServersOnDesktop = true;
          ShowRemovableMediaOnDesktop = true;
          _FXSortFoldersFirst = true;
          # When performing a search, search the current folder by default
          FXDefaultSearchScope = "SCcf";
          FXInfoPanesExpanded = {
            General = true;
            OpenWith = true;
            Privileges = true;
          };
        };
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.screensaver" = {
          # Require password immediately after sleep or screen saver begins
          askForPassword = 1;
          askForPasswordDelay = 0;
        };
        "com.apple.screencapture" = {
          location = "~/Desktop";
          type = "png";
        };
        "com.apple.universalaccess" = {
          # Prevent a long touch of the alt/option key from turning on mouse keys, which makes half the keyboard unusable
          # Note to self: five presses of alt/option in a row turn it off. But I don't use mousekeys, so let's disable it
          useMouseKeysShortcutKeys = 0;
        };
        "com.apple.Safari" = {
          # Privacy: don’t send search queries to Apple
          UniversalSearchEnabled = false;
          SuppressSearchSuggestions = true;
          # Press Tab to highlight each item on a web page
          WebKitTabToLinksPreferenceKey = true;
          ShowFullURLInSmartSearchField = true;
          # Prevent Safari from opening ‘safe’ files automatically after downloading
          AutoOpenSafeDownloads = false;
          ShowFavoritesBar = false;
          IncludeInternalDebugMenu = true;
          IncludeDevelopMenu = true;
          WebKitDeveloperExtrasEnabledPreferenceKey = true;
          WebContinuousSpellCheckingEnabled = true;
          WebAutomaticSpellingCorrectionEnabled = false;
          AutoFillFromAddressBook = false;
          AutoFillCreditCardData = false;
          AutoFillMiscellaneousForms = false;
          WarnAboutFraudulentWebsites = true;
          WebKitJavaEnabled = false;
          WebKitJavaScriptCanOpenWindowsAutomatically = false;
          "com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks" = true;
          "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
          "com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled" = false;
          "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled" = false;
          "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabledForLocalFiles" = false;
          "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically" = false;
        };
        "com.apple.mail" = {
          # Disable inline attachments (just show the icons)
          DisableInlineAttachmentViewing = false;
          ShouldShowUnreadMessagesInBold = true;
          ShowActivity = false;
          ShowBccHeader = true;
          ShowCcHeader = true;
          ShowComposeFormatInspectorBar = true;
          NSUserKeyEquivalents = {
            Send = "@\\U21a9";
          };
        };
        "com.apple.ActivityMonitor" = {
          OpenMainWindow = true;
          IconType = 5; # visualize cpu in dock icon
          ShowCategory = 0; # show all processes
          SortColumn = "CPUUsage";
          SortDirection = 0;
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        "com.apple.print.PrintingPrefs" = {
          # Automatically quit printer app once the print jobs complete
          "Quit When Finished" = true;
        };
        # Note: this will merge (I hope) with the saved and modified plist with the shortcuts
        # "com.amethyst.Amethyst" = {
        #   "enables-layout-hud" = true;
        #   "enables-layout-hud-on-space-change" = false;
        #   "smart-window-margins" = true;
        #   "float-small-windows" = true;
        #   SUEnableAutomaticChecks = false;
        #   SUSendProfileInfo = false;
        #   floating = [
        #     {
        #       id = "com.raycase.macos";
        #       "window-titles" = [];
        #     }
        #     {
        #       id = "com.apple.systempreferences";
        #       "window-titles" = [];
        #     }
        #     {
        #       id = "com.kapeli.dashdoc";
        #       "window-titles" = [];
        #     }
        #     {
        #       id = "com.markmcguill.strongbox.mac";
        #       "window-titles" = [];
        #     }
        #     {
        #       id = "com.yubico.yubioath";
        #       "window-titles" = [];
        #     }
        #   ];
        #   "window-resize-step" = 5;
        #   "window-margins" = 1;
        #   "window-margin-size" = 5;
        #   # TODO: Amethyst uses binary blobs for keyboard shortcuts. How to capture here? And defaults read truncates...
        #   "mouse-follows-focus" = false;
        #   "mouse-resizes-windows" = true;
        #   "follow-space-thrown-windows" = true;
        #   layouts = [
        #     "widescreen-tall"
        #     "wide"
        #     "tall"
        #     "row"
        #     "column"
        #     "fullscreen"
        #     "bsp"
        #     "floating"
        #   ];
        # };
        "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
        # Prevent Photos from opening automatically when devices are plugged in
        "com.apple.ImageCapture".disableHotPlug = true;
      };
    };

    system.activationScripts = {
      extraActivation = {
        enable = true;
        text = ''
          echo "Activating extra preferences..."
          # Close any open System Preferences panes, to prevent them from overriding
          # settings we’re about to change
          osascript -e 'tell application "System Preferences" to quit'

          # Show the ~/Library folder
          #chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library

          # Add the keyboard shortcut ⌘ + Enter to send an email in Mail.app
          # defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Send" "@\U21a9"

          # Display emails in threaded mode, sorted by date (newest at the top)
          defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
          defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending" -string "no"
          defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"

          # Doesn't seem to matter in the global domain so trying this
          defaults write "/Library/Preferences/com.apple.SoftwareUpdate" ScheduleFrequency 1

          defaults write com.apple.spotlight orderedItems -array \
            '{"enabled" = 1;"name" = "APPLICATIONS";}' \
            '{"enabled" = 1;"name" = "DIRECTORIES";}' \
            '{"enabled" = 1;"name" = "PDF";}' \
            '{"enabled" = 1;"name" = "DOCUMENTS";}' \
            '{"enabled" = 1;"name" = "PRESENTATIONS";}' \
            '{"enabled" = 1;"name" = "SPREADSHEETS";}' \
            '{"enabled" = 1;"name" = "MENU_OTHER";}' \
            '{"enabled" = 1;"name" = "CONTACT";}' \
            '{"enabled" = 1;"name" = "IMAGES";}' \
            '{"enabled" = 1;"name" = "MESSAGES";}' \
            '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
            '{"enabled" = 1;"name" = "EVENT_TODO";}' \
            '{"enabled" = 1;"name" = "MENU_CONVERSION";}' \
            '{"enabled" = 1;"name" = "MENU_EXPRESSION";}' \
            '{"enabled" = 0;"name" = "FONTS";}' \
            '{"enabled" = 0;"name" = "BOOKMARKS";}' \
            '{"enabled" = 0;"name" = "MUSIC";}' \
            '{"enabled" = 0;"name" = "MOVIES";}' \
            '{"enabled" = 0;"name" = "SOURCE";}' \
            '{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
            '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
            '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'

          echo "Turning on verbose boot startup"
          sudo nvram boot-args="-v"

          echo "Restoring system hotkeys and amethyst hotkeys"
          defaults import com.apple.symbolichotkeys ${../../dotfiles/plists/symbolichotkeys.plist}
          #defaults import com.amethyst.Amethyst ${../../dotfiles/plists/amethyst.plist}

        '';
        # to create an importable plist, see export-plists.sh
      };
      # TODO: find the new root postActivation script name
      # then do the activateSettings with su or sudo to primary user
      # postUserActivation.text = ''
      #   # Following line should allow us to avoid a logout/login cycle
      #   echo "Activating settings"
      #   /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      # '';
    };
  };

  flake.modules.homeManager.prefs = {
    home.file."Library/KeyBindings/DefaultKeyBinding.dict".source = ../../dotfiles/DefaultKeyBinding.dict;
    # company colors -- may still need to "install" them from a color picker window
    home.file."Library/Colors/IronCore-Branding-June-17.clr".source = ../../dotfiles/IronCore-Branding-June-17.clr;
  };
}
