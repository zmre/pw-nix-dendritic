{
  flake.darwinModules.network-gui = {
    homebrew.casks = [
      "tailscale-app" # moved from darwin services cuz exit nodes https://tailscale.com/kb/1065/macos-variants#comparison-table
    ];
  };
  flake.modules.homeManager.network = {
    inputs,
    pkgs,
    lib,
    ...
  }: let
    system = pkgs.stdenvNoCC.hostPlatform.system;
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
          };
        };
        includes = ["*.conf"];
        extraConfig = ''
          AddKeysToAgent yes
        '';
      };
      ssh-agent = {
        enable = true;
        enableZshIntegration = true;
      };
    };
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
