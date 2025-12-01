{inputs, ...}: {
  flake-file.inputs.pwaerospace.url = "github:zmre/aerospace-sketchybar-nix-lua-config";

  flake.darwinModules.window-mgmt = {pkgs, ...}: let
    system = pkgs.stdenvNoCC.hostPlatform.system;
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
    launchd = {
      # enable by default is true only on darwin
      agents = {
        "com.zmre.pwaerospace" = {
          command = "${pwaerospace}/bin/pwaerospace";
          serviceConfig = {
            Label = "com.zmre.pwaerospace";
            Program = "${pwaerospace}/bin/pwaerospace";
            RunAtLoad = true;
            KeepAlive = true;
          };
        };
      };
    };
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
}
