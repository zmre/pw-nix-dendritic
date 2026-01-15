{
  flake.darwinModules.network-gui = {
    homebrew.brews = [
      "iperf3"
    ];
    homebrew.casks = [
      "tailscale-app" # moved from darwin services cuz exit nodes https://tailscale.com/kb/1065/macos-variants#comparison-table
    ];
  };

  flake.modules.homeManager.network = {
    pkgs,
    lib,
    ...
  }: let
    # system = pkgs.stdenvNoCC.hostPlatform.system;
    inherit (pkgs.stdenv) isLinux;
  in {
    home.packages = with pkgs; [
      # network
      gping
      dig
      curl
      bandwhich # bandwidth monitor by process
      #pkgs.sniffnet # x-platform gui traffic monitor (rust)
      # not building on m1 right now
      #bmon # bandwidth monitor by interface
      static-web-server # serve local static files
      aria2 # cli downloader
      # ncftp
      #pietrasanta-traceroute
      hostname
      trippy # mtr alternative
      xh # rust version of httpie / better curl
      mtr
      iftop
      ipcalc
    ];
    programs = {
      ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = {
          "*" = {
            compression = true;
            controlMaster = "auto";
            forwardAgent = true;
          };
        };
        includes = ["*.conf"];
        extraConfig = ''
          AddKeysToAgent yes
        '';
      };
    };
    # Linux-only: use systemd ssh-agent service
    services.ssh-agent = lib.mkIf isLinux {
      enable = true;
      # Disable default integration - it only sets SSH_AUTH_SOCK if empty,
      # which fails when tmux or display manager sets a stale value
      enableZshIntegration = false;
      enableBashIntegration = false;
    };

    # Unconditionally set SSH_AUTH_SOCK to the systemd ssh-agent socket (Linux only)
    # Use /run/user/$(id -u) instead of $XDG_RUNTIME_DIR because XDG_RUNTIME_DIR
    # may not be set in all contexts (e.g., SSH sessions, tmux, some display managers)
    programs.zsh.initContent = lib.mkIf isLinux ''
      export SSH_AUTH_SOCK="/run/user/$(id -u)/ssh-agent"
    '';
    programs.bash.initExtra = lib.mkIf isLinux ''
      export SSH_AUTH_SOCK="/run/user/$(id -u)/ssh-agent"
    '';
    home.file.".config/curlrc".text = ''
      connect-timeout 10
      speed-time 30
      speed-limit 1000
      retry 2
      retry-max-time 30
      location
      max-redirs 3
    '';
  };
}
