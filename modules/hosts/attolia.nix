{inputs, ...}: let
  username = "pwalsh";
  hostname = "attolia";

  # Helper: filter a list of module names to only those that exist in moduleSet
  filterModules = moduleSet: names:
    builtins.filter (m: m != null) (
      map (n: moduleSet.${n} or null) names
    );

  # Single source of truth: all desired modules by name
  wantedModules = [
    # System/darwin-only
    "attolia-config"
    "brew"
    "prefs"
    "remote-builders"
    "system"
    "terminfo"
    "touchid"
    "window-mgmt"
    "hardened"

    # Cross-platform or home-manager only
    "ai"
    "ai-gui"
    "browsers-gui"
    "comms-gui"
    "dev-gui"
    "dev"
    "espanso"
    "filemanagement"
    "filemanagement-gui"
    "iron"
    "media"
    "media-gui"
    "network"
    "network-gui"
    "prose"
    "scripts"
    "security"
    "security-gui"
    "shell"
    "term-gui"
    "vim"
    "vim-gui"
    "virtualization"
  ];

  darwinMods = filterModules inputs.self.darwinModules wantedModules;
  homeMods = filterModules inputs.self.modules.homeManager wantedModules;
in {
  flake.darwinConfigurations.${hostname} = inputs.darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = darwinMods;
  };

  flake.darwinModules.attolia-config = {pkgs, ...}: {
    config = {
      users.users.${username} = {
        home = "/Users/${username}";
        shell = pkgs.stable.zsh;
        packages = with pkgs; [tree];
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

      home-manager.users.${username} = {
        imports = homeMods;
        home.username = username;
        home.homeDirectory = "/Users/${username}";
        home.stateVersion = "20.09";
        targets.darwin.copyApps.enable = true;
        targets.darwin.linkApps.enable = false;
      };
      system.stateVersion = 4;
    };
  };
}
