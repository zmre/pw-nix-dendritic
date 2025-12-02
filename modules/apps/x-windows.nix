{inputs, ...}: {
  flake.nixosModules.x-windows = {pkgs, ...}: {
    services = {
      # Enable the X11 windowing system.
      xserver.enable = true;
      displayManager = {
        sddm.enable = true;
        sddm.wayland.enable = true;
      };
      desktopManager.plasma6.enable = true;
    };
    programs.firefox.enable = true;
    environment.systemPackages = with pkgs; [
      wezterm
    ];
  };
}
