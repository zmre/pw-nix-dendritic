{inputs, ...}: {
  flake-file.inputs.yazi-flavors.url = "github:yazi-rs/flavors";
  flake-file.inputs.yazi-flavors.flake = false;
  flake-file.inputs.yazi-quicklook.url = "github:vvatikiotis/quicklook.yazi";
  flake-file.inputs.yazi-quicklook.flake = false;

  flake.darwinModules.filemanagement-gui = {pkgs, ...}: {
    homebrew.casks = [
      "dropbox"
      "google-drive"
      "proton-drive"
      "sync"
      "transmission"
    ];
    homebrew.masApps = {
      "DaisyDisk" = 411643860;
    };
  };

  flake.modules.homeManager.filemanagement = {
    pkgs,
    lib,
    ...
  }: let
    system = pkgs.stdenvNoCC.hostPlatform.system;
  in {
    home.packages = with pkgs; [
      dust
      file
      fzy
      curl
      duf # df alternative showing free disk space
      fswatch
      tree
      rsync

      # compression
      atool
      unzip
      gzip
      xz
      zip
    ];
    programs = {
      eza.enable = true;
      fd.enable = true;
      ripgrep.enable = true;
      bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras; [batman batgrep];
        config = {
          theme = "Dracula"; # I like the TwoDark colors better, but want bold/italic in markdown docs
          #pager = "less -FR";
          pager = "page -WO -q 90000";
          italic-text = "always";
          style = "plain"; # no line numbers, git status, etc... more like cat with colors
        };
      };
      yazi = {
        enable = true;
        enableZshIntegration = true;
        flavors = {
          catppuccin-mocha = (inputs.yazi-flavors) + /catppuccin-mocha.yazi;
        };
        theme = {
          use = "catppuccin-mocha";

          status = {
            separator_open = "";
            separator_close = "";
            separator_style = {
              fg = "#45475a";
              bg = "#45475a";
            };

            # Mode
            mode_normal = {
              fg = "#1e1e2e";
              bg = "#a6e3a1";
              bold = true;
            };
            mode_select = {
              fg = "#1e1e2e";
              bg = "#a6e3a1";
              bold = true;
            };
            mode_unset = {
              fg = "#1e1e2e";
              bg = "#f2cdcd";
              bold = true;
            };

            # Progress
            progress_label = {
              fg = "#ffffff";
              bold = true;
            };
            progress_normal = {
              fg = "#89b4fa";
              bg = "#45475a";
            };
            progress_error = {
              fg = "#f38ba8";
              bg = "#45475a";
            };
          };

          tasks = {
            border = {fg = "#a6e3a1";};
            title = {};
            hovered = {underline = true;};
          };
        };
        initLua = ../../dotfiles/yazi/init.lua;
        keymap = {
          mgr = {
            append_keymap = [
              {
                on = ["," " "]; # comma then space to preview, which is weird in yazi land where comma triggers sort options, but it works okay for me
                run = ["plugin quicklook"];
                desc = "Macos Quicklook";
              }
              {
                on = ["g" "r"]; # most g <something> commands go somewhere specific but this one goes to root of current folder
                run = ''shell 'ya pub dds-cd --str "$(git rev-parse --show-toplevel)"' --confirm'';
                desc = "Git root";
              }
              {
                on = ["g" "k"];
                run = "cd ~/Desktop";
                desc = "Goto Desktop";
              }
              {
                on = ["g" "n"];
                run = "cd ~/Notes";
                desc = "Goto Notes";
              }
            ];
          };
        };
        plugins = {
          quicklook = inputs.yazi-quicklook;
          folder-rules = ../../dotfiles/yazi/plugins/folder-rules.yazi;
        };
        settings = {
          title_format = "y ({cwd})";
          mgr = {
            sort_by = "natural";
            sort_dir_first = true;
            sort_reverse = true;
            sort_sensitive = false; # case insensitive sorting
            sort_translit = false; # if true, replaces Â as A, Æ as AE, etc
            linemode = "size_and_mtime";
          };
          opener = {
            play = [
              {
                run = ''mpv --force-window "$@"'';
                for = "unix"; # here unix is macos and linux
                orphan = true;
              }
              {
                run = ''mediainfo "$1"; echo "Press enter to exit"; read _'';
                block = true;
                desc = "Show media info";
                for = "unix";
              }
            ];
            edit = [
              {
                run = ''nvim "$@"'';
                block = true;
                desc = "nvim";
                for = "unix";
              }
              {
                run = ''pwneovide "$@"'';
                orphan = true;
                desc = "neovide";
                for = "unix";
              }
            ];
            reveal = [
              # if folder, open explorer current location
              {
                run = ''xdg-open "$(dirname "$1")"'';
                desc = "Reveal";
                for = "linux";
              }
              {
                run = ''open -R "$1"'';
                desc = "Reveal in Finder";
                for = "macos";
              }
              {
                run = ''explorer /select,"%1"'';
                orphan = true;
                desc = "Reveal";
                for = "windows";
              }
              {
                run = ''exiftool "$1"; echo "Press enter to exit"; read _'';
                block = true;
                desc = "Show EXIF";
                for = "unix";
              }
            ];
            open = [
              {
                run = ''open "$@"'';
                desc = "Open";
                for = "macos";
              }
              {
                run = ''open "$@"'';
                desc = "Open MacOS"; # adding twice to see if I can get this to show up inside yazi-nvim
                for = "macos";
              }
              {
                run = ''xdg-open "$1"'';
                desc = "Open";
                for = "linux";
              }
            ];
          };
          open = {
            rules = [
              # Folder
              {
                name = "*/";
                use = ["open" "reveal"];
              } # open explorer of current selected directory
              # Text
              {
                mime = "text/*";
                use = ["edit" "reveal"];
              }
              # Image
              {
                mime = "image/*";
                use = ["open" "reveal"];
              }
              # Media
              {
                mime = "{audio,video}/*";
                use = ["play" "reveal"];
              }
              # Archive
              {
                mime = "application/{,g}zip";
                use = ["extract" "reveal"];
              }
              {
                mime = "application/x-{tar,bzip*,7z-compressed,xz,rar}";
                use = ["extract" "reveal"];
              }
              # JSON
              {
                mime = "application/{json,x-ndjson}";
                use = ["edit" "reveal"];
              }
              {
                mime = "*/javascript";
                use = ["edit" "reveal"];
              }
              # Empty file
              {
                mime = "inode/x-empty";
                use = ["edit" "reveal"];
              }
              # Fallback
              {
                name = "*";
                use = ["open" "reveal"];
              }
            ];
          };
        };
        shellWrapperName = "y";
        theme = {};
      };
    };
  };
}
