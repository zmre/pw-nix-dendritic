{inputs, ...}: let
  username = "pwalsh";
  username2 = "awalsh";
  hostname = "cintra";

  # Helper: filter a list of module names to only those that exist in moduleSet
  filterModules = moduleSet: names:
    builtins.filter (m: m != null) (
      map (n: moduleSet.${n} or null) names
    );

  # Single source of truth: all desired modules by name
  wantedModules = [
    "hardware-options"
    # System/darwin-only
    "cintra-config"
    "brew"
    "prefs"
    "determinate"
    "system"
    "terminfo"
    "touchid"

    # Cross-platform or home-manager only
    "browsers-gui"
    "comms-gui"
    "dev"
    "filemanagement"
    "filemanagement-gui"
    "finance"
    "finance-gui"
    "media"
    "media-gui"
    "network"
    "network-gui"
    "scripts"
    "shell"
    "term-gui"
    "vim"
    "vim-gui"
  ];

  darwinMods = filterModules inputs.self.darwinModules wantedModules;
  homeMods = filterModules inputs.self.modules.homeManager wantedModules;
in {
  flake.darwinConfigurations.${hostname} = inputs.darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = darwinMods;
  };

  flake.darwinModules.cintra-config = {pkgs, ...}: {
    config = {
      users.users.${username} = {
        home = "/Users/${username}";
        shell = pkgs.stable.zsh;
        packages = with pkgs; [tree];
      };
      users.users.${username2} = {
        home = "/Users/${username2}";
        shell = pkgs.stable.zsh;
        packages = with pkgs; [tree];
      };
      powerExtras.enable = false;
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

      home-manager.users.${username} = {
        imports = homeMods;
        home.username = username;
        home.homeDirectory = "/Users/${username}";
        home.stateVersion = "20.09";
        targets.darwin.copyApps.enable = true;
        targets.darwin.linkApps.enable = false;
      };
      home-manager.users.${username2} = {
        imports = homeMods;
        home.username = username2;
        home.homeDirectory = "/Users/${username2}";
        home.stateVersion = "20.09";
        targets.darwin.copyApps.enable = true;
        targets.darwin.linkApps.enable = false;
      };
      system.stateVersion = 4;
    };
  };
}
