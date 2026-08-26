{inputs, ...}: {
  flake.nixosModules.x-windows = {pkgs, ...}: {
    services = {
      # Enable the X11 windowing system.
      desktopManager.gnome.enable = true;
      displayManager = {
        gdm.enable = true;
      };
      xserver = {
        enable = true;
        # desktopManager.cinnamon.enable = true;
        defaultDepth = 24;
        xkb.options = "caps:escape";
        xkb.layout = "us";
        # displayManager = {
        #sddm.enable = true;
        #sddm.wayland.enable = true;
        #plasma-login-manager.enable = true;
        # lightdm.enable = true;
        #};
        # Keyboard
        autoRepeatDelay = 265;
        autoRepeatInterval = 20;
      };
      #desktopManager.plasma6.enable = true;
    };
    #programs.firefox.enable = true;
    environment.systemPackages = with pkgs; [
      wezterm
    ];
  };
}
