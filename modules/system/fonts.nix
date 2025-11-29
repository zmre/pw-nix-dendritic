{
  flake.darwinModules.system = {pkgs, ...}: {
    fonts.packages = with pkgs; [
      # powerline-fonts
      # source-code-pro
      roboto-slab
      source-sans-pro
      nerd-fonts.fira-code
      nerd-fonts.hasklug
      nerd-fonts.droid-sans-mono
      nerd-fonts.dejavu-sans-mono
      nerd-fonts.im-writing
      nerd-fonts.jetbrains-mono
      nerd-fonts.meslo-lg
      nerd-fonts.sauce-code-pro
      nerd-fonts.inconsolata
      nerd-fonts.symbols-only
      sketchybar-app-font
      montserrat
      raleway
      vegur
      noto-fonts
      vista-fonts # needed for msoffice
    ];
    system.defaults = {
      NSGlobalDomain = {
        AppleFontSmoothing = 2;
        "com.apple.mouse.tapBehavior" = 1; # tap to click
      };
    };
  };
  flake.nixosModules.fonts = {pkgs, ...}: {
    fonts = {
      enableDefaultPackages = true;
      fontconfig.enable = true;
      fontDir.enable = true;
      enableGhostscriptFonts = false;
      packages = with pkgs; [
        powerline-fonts
        source-code-pro
        nerd-fonts.fira-code
        nerd-fonts.hasklug
        nerd-fonts.droid-sans-mono
        nerd-fonts.dejavu-sans-mono
        nerd-fonts.im-writing
        nerd-fonts.jetbrains-mono
        nerd-fonts.meslo-lg
        nerd-fonts.sauce-code-pro
        nerd-fonts.inconsolata
        nerd-fonts.symbols-only
        vegur
        noto-fonts
      ];
      fontconfig.defaultFonts = {
        monospace = ["MesloLGS Nerd Font Mono" "Noto Mono"];
        sansSerif = ["MesloLGS Nerd Font" "Noto Sans"];
        serif = ["Noto Serif"];
      };
    };
  };
}
