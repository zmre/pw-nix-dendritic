{
  inputs,
  config,
  ...
}: let
  username = "pwalsh";
  hostname = "attolia";
in {
  flake.darwinConfigurations.${hostname} = inputs.darwin.lib.darwinSystem {
    #system = "aarch64-darwin"; # TODO: is this needed?
    modules = with config.flake.darwinModules; [
      system # pulls everything in that always is needed for darwin loads
    ];
  };

  flake.homeConfigurations.avalon = inputs.home-manager.lib.homeManagerConfiguration {
    modules = with config.flake.modules.homeManager; [
      {
        home.username = username;
        home.homeDirectory = "/Users/${username}";
        home.stateVersion = "25.05";
      }
    ];
  };

  flake.darwinModules.system = {pkgs, ...}: {
    networking.hostName = hostname;
    system.primaryUser = username;
    nixpkgs.hostPlatform = "aarch64-darwin";
    # pathsToLink = ["/Applications"];
    environment.systemPath = [
      "/run/current-system/sw/bin"
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
    ];
    users.users.${username} = {
      home = "/Users/${username}";
      shell = pkgs.zsh;
      packages = with pkgs; [
        tree # this is just a test, really
      ];
    };

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 6;
  };
}
