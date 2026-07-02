{
  flake.modules.homeManager.scripts = {
    pkgs,
    lib,
    ...
  }: let
    bright = pkgs.writeShellApplication {
      name = "bright.sh";
      # Below are needed for bright.sh script, but this is an import in home-manager and homebrew is set under darwin so...
      # these are moving over there.
      # homebrew.brews = [
      #   "brightness"
      #   "ddcctl"
      # ];
      runtimeInputs = [];
      text = builtins.readFile ../../dotfiles/scripts/bright.sh;
    };
    yt = pkgs.writeShellApplication {
      name = "yt";
      runtimeInputs = with pkgs; [yt-dlp];
      # update 2025-01-16
      # started getting 403 errors and tried a bunch of things; ultimately using the ios client and not using cookies solved for me, per this thread:
      # https://github.com/yt-dlp/yt-dlp/issues/10046
      # but i suspect this is only sometimes the right answer so I've added the modified command that worked for me to run only if yt-dlp has a non-zero exit code on first try
      # with a three second sleep in there
      text = ''
        yt-dlp --remux-video mp4 --embed-subs --write-auto-sub --embed-thumbnail --write-subs --sub-langs 'en.*,en-orig,en' --embed-chapters --sponsorblock-mark default --sponsorblock-remove default --no-prefer-free-formats --check-formats --embed-metadata --cookies-from-browser safari --user-agent 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36' "$1" || sleep 3 && yt-dlp -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4] / bv*+ba/b" --remux-video mp4 --embed-subs --write-auto-sub --embed-thumbnail --write-subs --sub-langs 'en.*,en-orig,en' --embed-chapters --sponsorblock-mark default --sponsorblock-remove default --no-prefer-free-formats --check-formats  --embed-metadata  --user-agent 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36' --extractor-args "youtube:player_client=ios" "$1"
      '';
    };
    yt-fix = pkgs.writeShellApplication {
      name = "yt-fix";
      runtimeInputs = with pkgs; [ffmpeg deterministic-uname];
      text = builtins.readFile ../../dotfiles/scripts/yt-fix;
    };
    # syncm = pkgs.writeShellApplication {
    #   name = "syncm";
    #   runtimeInputs = [pkgs.rsync];
    #   text = "rsync -avhP --delete --progress \"$HOME/Sync/Private/PW Projects/Magic/Videos/\" pwalsh@synology1.savannah-basilisk.ts.net:/volume1/video/Magic/";
    # };
    desktop-hide = pkgs.writeShellApplication {
      name = "desktop-hide";
      runtimeInputs = [];
      text = ''
        defaults write com.apple.finder CreateDesktop false
        killall Finder
      '';
    };
    desktop-show = pkgs.writeShellApplication {
      name = "desktop-show";
      runtimeInputs = [];
      text = ''
        defaults write com.apple.finder CreateDesktop true
        killall Finder
      '';
    };
    transcribe-rode-meeting = pkgs.writeShellApplication {
      name = "transcribe-rode-meeting";
      runtimeInputs = with pkgs; [ffmpeg stable.whisper-cpp];
      text = builtins.readFile ../../dotfiles/scripts/transcribe-rode-meeting;
    };
    transcribe-video-to-subtitles = pkgs.writeShellApplication {
      name = "transcribe-video-to-subtitles";
      runtimeInputs = with pkgs; [ffmpeg stable.whisper-cpp];
      text = builtins.readFile ../../dotfiles/scripts/transcribe-video-to-subtitles;
    };
    cleanup-dev-disk = pkgs.writeShellApplication {
      name = "cleanup-dev-disk"; # this is murph's script, defaults to dry run mode, handles nix (incl flake/direnv), rust, docker
      # kondo is the app that handles rust, python, java, scala, etc., but not nix or docker
      # Usage:
      #   cleanup-dev-disk           # dry-run (safe, shows what WOULD be freed)
      #   cleanup-dev-disk --run     # actually execute cleanup
      #   cleanup-dev-disk --run --section nix
      #   cleanup-dev-disk --run --section docker
      #   cleanup-dev-disk --run --section rust
      #runtimeInputs = with pkgs; [];
      text = builtins.readFile ../../dotfiles/scripts/cleanup-dev-disk.sh;
    };
  in {
    home.packages =
      [
        yt
        #syncm
        yt-fix
        transcribe-rode-meeting
        transcribe-video-to-subtitles
        cleanup-dev-disk
      ]
      ++ lib.optionals pkgs.stdenvNoCC.isLinux []
      ++ lib.optionals pkgs.stdenvNoCC.isDarwin [
        bright
        desktop-hide
        desktop-show
      ];
  };
}
