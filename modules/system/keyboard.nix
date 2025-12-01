{
  flake.darwinModules.system = {pkgs, ...}: {
    system.keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
    system.defaults = {
      # trackpad settings
      trackpad = {
        # silent clicking = 0, default = 1
        ActuationStrength = 0;
        # enable tap to click
        Clicking = true;
        Dragging = true; # tap and a half to drag
        # three finger click and drag
        TrackpadThreeFingerDrag = true;
      };
      NSGlobalDomain = {
        "com.apple.swipescrolldirection" = true; # "natural" scrolling
        "com.apple.keyboard.fnState" = true;
        "com.apple.springing.enabled" = false;
        "com.apple.trackpad.scaling" = 3.0; # fast
        "com.apple.trackpad.enableSecondaryClick" = true;
        "com.apple.mouse.tapBehavior" = 1; # tap to click
        # enable full keyboard control
        # (e.g. enable Tab in modal dialogs)
        AppleKeyboardUIMode = 3;
        # no popup menus when holding down letters
        ApplePressAndHoldEnabled = false;
        # delay before repeating keystrokes
        InitialKeyRepeat = 14;
        # delay between repeated keystrokes upon holding a key
        KeyRepeat = 1;
      };
    };
  };

  flake.nixosModules.gui = {pkgs, ...}: {
    services.xserver = {
      xkb.options = "caps:escape";
      xkb.layout = "us";
      autoRepeatDelay = 265;
      autoRepeatInterval = 20;
    };
    # Enable touchpad support
    services.libinput = {
      enable = true;
      touchpad = {
        accelSpeed = "0.7";
        naturalScrolling = true;
        middleEmulation = true;
        tapping = true;
        scrollMethod = "twofinger";
        #disableWhileTyping = true;
      };
    };
  };
}
