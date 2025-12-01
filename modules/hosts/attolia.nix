{
  inputs,
  config,
  ...
}: let
  username = "pwalsh";
  hostname = "attolia";
in {
  flake.darwinConfigurations.${hostname} = inputs.darwin.lib.darwinSystem {
    modules = with config.flake.darwinModules; [
      attolia-config
      system # pulls everything in that always is needed for darwin loads
      prefs
      touchid
      ai-gui
      brew
      browsers-gui
      comms-gui
      dev-gui
      filemanagement-gui
      media-gui
      security
      security-gui
      term-gui
      terminfo
      window-mgmt
    ];
  };

  flake.darwinModules.attolia-config = {pkgs, ...}: {
    config = {
      users.users.${username} = {
        home = "/Users/${username}";
        shell = pkgs.stable.zsh;
        packages = with pkgs; [
          tree # this is just a test, really
        ];
      };
      networking.hostName = hostname;
      system.primaryUser = username;
      nixpkgs.hostPlatform = "aarch64-darwin";
      nixpkgs.config.allowUnfree = true;
      environment.systemPath = [
        "/run/current-system/sw/bin"
        "/opt/homebrew/bin"
        "/opt/homebrew/sbin"
      ];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;

      # Configure home-manager for the pwalsh user
      home-manager.users.${username} = {
        imports = with config.flake.modules.homeManager; [
          ai
          dev
          dev-gui
          espanso
          filemanagement
          iron
          network
          media
          prefs
          prose
          scripts
          security
          shell
          vim
          vim-gui
        ];
        home.username = username;
        home.homeDirectory = "/Users/${username}";
        home.stateVersion = "25.11";
        targets.darwin.copyApps.enable = true;
      };
      system.stateVersion = 6;
    };
  };
}
