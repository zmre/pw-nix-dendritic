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
      touchid
      terminfo
    ];
  };

  # flake.homeConfigurations.avalon = inputs.home-manager.lib.homeManagerConfiguration {
  #   modules = with config.flake.homeManager; [
  #     {
  #       home.username = username;
  #       home.homeDirectory = "/Users/${username}";
  #       home.stateVersion = "25.05";
  #     }
  #     ai
  #     dev
  #     filemanagement
  #     network
  #     media
  #     shell
  #     vim
  #   ];
  # };

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
      # pathsToLink = ["/Applications"];
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
          filemanagement
          network
          media
          shell
          vim
        ];

        # home.username = username;
        # home.homeDirectory = "/Users/${username}";
        home.stateVersion = "25.05";
      };
      system.stateVersion = 6;
    };

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
  };
}
