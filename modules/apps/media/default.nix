{
  flake.darwinModules.media-gui = {
    homebrew.casks = [
      "adobe-creative-cloud"
      "calibre" # available in nix, but marked broken for darwin as of 2025-09-18
      "descript"
      "pikachuexe/freetube/pikachuexe-freetube" # TODO: this is in nixpkgs now for darwin -- try there and see if we get arm
      "imageoptim"
      "insta360-studio"
      "keycastr" # show keys being pressed
      "noun-project"
      #"obs"
      "stolendata-mpv" # 2024-12-11 switching to brew but keeping hm config; gui not launching
      "screenflow"
      "subler" # used to edit metadata on videos
    ];
    homebrew.masApps = {
      "Gifox" = 1461845568; # For short animated gif screen caps
      "Kindle" = 302584613;
    };
    homebrew.brews = [
      "nghttp2" # needed for yt-dlp curl-impersonate
      "yt-dlp" # youtube downloader / 2024-11-19 moved back to nix now that curl-cffi (curl-impersonate) is supported
      "zstd" # needed for yt-dlp curl-impersonate
    ];
  };

  flake.nixosModules.media-gui = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      plex-media-player
    ];
  };

  flake.modules.homeManager.media = {pkgs, ...}: let
    system = pkgs.stdenvNoCC.hostPlatform.system;
  in {
    home.packages = with pkgs; [
      sourceHighlight # for lf preview
      ffmpeg-full.bin
      ffmpegthumbnailer
      imagemagick
      mediainfo
      exiftool
      exif
      optipng
    ];
    programs.yt-dlp = {
      # previously had this disabled because I needed curl-impersonate (curl-cffi lib) to get past cloudflare stuff
      # but as of 2024-11-19 that appears to be in place
      enable = true;
      settings = {
        embed-thumbnail = true;
        embed-subs = true;
        embed-chapters = true;
        sponsorblock-remove = "default";
        embed-metadata = true;
      };
    };
    programs.mpv = {
      enable = true;
      # Until someone changes makeWrapper to makeBinaryWrapper in https://github.com/NixOS/nixpkgs/issues/356860, we need to use the brew version to avoid the
      # issue where post macos 15.1, gui doesn't start from Finder (The application “Finder” does not have permission to open “(null).”)
      package = pkgs.emptyDirectory;
      #scripts = with pkgs.mpvScripts; [thumbnail sponsorblock uosc];
      config = {
        osc = true;
        # Use a large seekable RAM cache even for local input.
        cache = true;
        save-position-on-quit = false;
        #x11-bypass-compositor = true;
        #no-border = true;
        msg-color = true;
        pause = true;
        # This will force use of h264 instead vp8/9 so hardware acceleration works
        ytdl-format = "bv*[ext=mp4]+ba/b";
        #ytdl-format = "bestvideo+bestaudio";
        # have mpv use yt-dlp instead of youtube-dl
        script-opts-append = "ytdl_hook-ytdl_path=${pkgs.yt-dlp}/bin/yt-dlp";
        autofit-larger = "100%x95%"; # resize window in case it's larger than W%xH% of the screen
        input-media-keys = "yes"; # enable/disable OSX media keys
        hls-bitrate = "max"; # use max quality for HLS streams

        user-agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:57.0) Gecko/20100101 Firefox/58.0";
      };
      bindings = {
        #"G" = "add sub-scale +0.1"; # increase the subtitle font size (this is the default)
        #"F" = "add sub-scale -0.1"; # decrease the subtitle font size (this is the default)
        #"r" = "add sub-pos -1"; # move subtitles up (this is the default)
        #"R" = "add sub-pos +1"; # move subtitles down (this is the default)
        #"PGUP" = "add chapter 1"; # seek to the next chapter (this is the default)
        #"PGDWN" = "add chapter -1"; # seek to the previous chapter (this is the default)
        #"g-c" = "script-binding select/select-chapter"; # chapter chooser (this is the default)
      };
      defaultProfiles = ["gpu-hq"];
    };
  };
}
