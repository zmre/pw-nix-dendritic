{inputs, ...}: {
  flake-file.inputs.hackernews-tui.url = "github:aome510/hackernews-TUI";
  flake-file.inputs.hackernews-tui.flake = false;

  flake.modules.homeManager.shell = {
    pkgs,
    config,
    lib,
    ...
  }: let
    hackernews-tui = pkgs.rustPlatform.buildRustPackage {
      name = "hackernews-tui";
      pname = "hackernews-tui";
      cargoLock = {lockFile = inputs.hackernews-tui + /Cargo.lock;};
      buildInputs =
        [pkgs.pkg-config pkgs.libiconv]
        ++ pkgs.lib.optionals pkgs.stdenv.isDarwin
        [pkgs.apple-sdk];
      src = inputs.hackernews-tui;
    };
  in {
    home.packages = with pkgs;
      [
        less
        page # like less, but uses nvim, which is handy for selecting out text and such
        file
        jq
        lynx
        poppler-utils # for pdf2text
        glow # browse markdown dirs
        mdcat # colorize markdown
        html2text
        neofetch # display key software/version info in term
        vimv # shell script to bulk rename
        procps
        pstree
        hackernews-tui
        btop
        kalker # cli calculator; alt. to bc and calc
        rink # calculator for unit conversions
        fortune
        kondo # free disk space by cleaning project build dirs
        zk # cli for indexing markdown files
      ]
      ++ (lib.optionals pkgs.stdenv.isDarwin [
        mactop
      ]);
    programs = {
      # Nice shell history https://atuin.sh -- experimenting with this 2024-07-26
      atuin = {
        enable = true;
        enableZshIntegration = true;
        flags = ["--disable-up-arrow"];
        settings = {
          update_check = false;
          search_mode = "fuzzy";
          inline_height = 33;
          common_prefix = ["sudo"];
          dialect = "us";
          workspaces = true;
          filter_mode = "host";
          filter_mode_shell_up_key_binding = "session"; # pointless now that I've disabled up arrow
          search_mode_shell_up_key_binding = "prefix";
          keymap_mode = "vim-insert";
          keymap_cursor = {
            emacs = "blink-underline";
            vim_insert = "steady-bar";
            vim_normal = "steady-block";
          };
          history_filter = [
            "^ "
            # "^innocuous-cmd .*--secret=.+"
          ];
        };
      };
      bat = {
        enable = true;
        #extraPackages = with pkgs.bat-extras; [ batman batgrep ];
        config = {
          theme = "Dracula"; # I like the TwoDark colors better, but want bold/italic in markdown docs
          #pager = "less -FR";
          pager = "page -WO -q 90000";
          italic-text = "always";
          style = "plain"; # no line numbers, git status, etc... more like cat with colors
        };
      };
      direnv = {
        enable = true;
        enableZshIntegration = true;
        enableNushellIntegration = true;
        nix-direnv.enable = true;
      };
      eza.enable = true; # replacement for "exa" which is now archived
      fzf = {
        enable = true;
        enableZshIntegration = false;
        tmux.enableShellIntegration = false;
        defaultCommand = "\fd --type f --hidden --exclude .git";
        fileWidgetCommand = "\fd --exclude .git --type f"; # for when ctrl-t is pressed
        changeDirWidgetCommand = "\fd --type d --hidden --follow --max-depth 3 --exclude .git";
      };
      home-manager.enable = true;
      nix-index.enable = true;
      starship = {
        enable = true;
        enableNushellIntegration =
          false; # I've manually integrated because of bugs 2023-04-05
        enableZshIntegration = true;
        enableBashIntegration = true;
        settings = {
          format = pkgs.lib.concatStrings [
            #"$os" # turns out it takes starship 20ms to figure out the OS at every prompt, but we can hard code it at build time
            # alt for linux: "🐧 "
            (
              if pkgs.stdenv.isLinux
              then "❄️"
              else if pkgs.stdenv.isDarwin
              then ""
              else "🪟 "
            )
            "$shell"
            "$username"
            "$hostname"
            "$singularity"
            "$kubernetes"
            "$directory"
            "$vcsh"
            "$fossil_branch"
            "$git_branch"
            # "$git_commit"
            # "$git_state"
            # "$git_status"
            # "$git_metrics"
            "$hg_branch"
            "$pijul_channel"
            "$sudo"
            "$jobs"
            "$line_break"
            "$battery"
            "$time"
            "$status"
            "$container"
            "$character"
          ];
          right_format = pkgs.lib.concatStrings [
            "$cmd_duration"
            "$shlvl"
            "$docker_context"
            "$package"
            "$c"
            "$cmake"
            "$daml"
            "$dart"
            "$deno"
            "$dotnet"
            "$elixir"
            "$elm"
            "$erlang"
            "$fennel"
            "$golang"
            "$guix_shell"
            "$haskell"
            "$haxe"
            "$helm"
            "$java"
            "$julia"
            "$kotlin"
            "$gradle"
            "$lua"
            "$nim"
            "$nodejs"
            "$ocaml"
            "$opa"
            "$perl"
            "$php"
            "$pulumi"
            "$purescript"
            "$python"
            "$raku"
            "$rlang"
            "$red"
            "$ruby"
            "$rust"
            "$scala"
            "$swift"
            "$terraform"
            "$vlang"
            "$vagrant"
            "$zig"
            "$buf"
            "$nix_shell"
            "$conda"
            "$meson"
            "$spack"
            "$memory_usage"
            "$aws"
            "$gcloud"
            "$openstack"
            "$azure"
            "$env_var"
            "$crystal"
            "$custom"
          ];
          character = {
            success_symbol = "[❯](purple)";
            error_symbol = "[❯](red)";
            vicmd_symbol = "[❮](green)";
          };
          scan_timeout = 30;
          add_newline = true;
          gcloud.disabled = true;
          aws.disabled = true;
          os.disabled = false;
          os.symbols.Macos = "";
          kubernetes = {
            disabled = false;
            context_aliases = {
              "gke_.*_(?P<var_cluster>[\\w-]+)" = "$var_cluster";
            };
          };
          git_status.style = "blue";
          git_metrics.disabled = false;
          git_branch.style = "bright-black";
          git_branch.format = "[  ](bright-black)[$symbol$branch(:$remote_branch)]($style) ";
          time.disabled = true;
          directory = {
            format = "[    ](bright-black)[$path]($style)[$read_only]($read_only_style)";
            truncation_length = 4;
            truncation_symbol = "…/";
            style = "bold blue"; # cyan
            truncate_to_repo = false;
          };
          directory.substitutions = {
            # Documents = " ";
            # Downloads = " ";
            # Music = " ";
            # Pictures = " ";
            "Library/Mobile Documents/com~apple~CloudDocs/Notes" = "Notes";
          };
          package.disabled = true;
          package.format = "version [$version](bold green) ";
          nix_shell.symbol = " ";
          rust.symbol = " ";
          shell = {
            disabled = false;
            format = "[$indicator]($style)";
            style = "bright-black";
            bash_indicator = " bsh";
            nu_indicator = " nu";
            fish_indicator = " ";
            zsh_indicator = ""; # don't show when in my default shell type
            unknown_indicator = " ?";
            powershell_indicator = " _";
          };
          cmd_duration = {
            format = "[$duration]($style)   ";
            style = "bold yellow";
            min_time_to_notify = 5000;
          };
          jobs = {
            symbol = "";
            style = "bold red";
            number_threshold = 1;
            format = "[$symbol]($style)";
          };
        };
      };
      tmux = {
        enable = true;
        keyMode = "vi";
        shell = "${pkgs.zsh}/bin/zsh";
        historyLimit = 10000;
        escapeTime = 0;
        extraConfig = builtins.readFile ../../dotfiles/tmux.conf;
        sensibleOnTop = true;
        plugins = with pkgs; [
          tmuxPlugins.sensible
          tmuxPlugins.open
        ];
      };
      zoxide = {
        enable = true;
        enableZshIntegration = true;
        enableNushellIntegration = false;
      };
      zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        # let's the terminal track current working dir but only builds on linux
        enableVteIntegration =
          if pkgs.stdenvNoCC.isDarwin
          then false
          else true;

        history = {
          expireDuplicatesFirst = true;
          ignoreSpace = true;
          save = 10000; # save 10,000 lines of history
        };
        defaultKeymap = "viins";
        # things to add to .zshenv
        envExtra = ''
          # don't use global env as it will slow us down
          skip_global_compinit=1
          # disable the reading of /etc/zshrc, which has redundant things and crap I don't want
          # like brew shellenv which takes forever, plus redundant compinit calls
          NOSYSZSHRC="1"
          LANGUAGE="en_US.UTF-8"
          LC_ALL="en_US.UTF-8"
        '';

        completionInit = ''
          # only update compinit once each day
          # better solution would be to pre-build zcompdump with compinit call then link it in
          # and never recalculate
          autoload -Uz compinit
          for dump in ~/.zcompdump(N.mh+24); do
            compinit
          done
          compinit -C

          # disable sort when completing `git checkout`
          zstyle ':completion:*:git-checkout:*' sort false
          # set descriptions format to enable group support
          zstyle ':completion:*:descriptions' format '[%d]'
          # set list-colors to enable filename colorizing
          zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        '';

        initContent = lib.mkBefore ''
          #zmodload zsh/zprof
          set -o vi
          bindkey -v


          jump_key_places(){
            cd "$(\fd . ~ ~/.config ~/src/sideprojects ~/src/icl ~/src/icl/website.worktree ~/src/personal ~/src/gh ~/Sync/Private/Finances ~/Sync/Private ~/Sync/IronCore\ Docs ~/Sync/IronCore\ Docs/Legal ~/Sync/IronCore\ Docs/Finances ~/Sync/IronCore\ Docs/Design ~/Notes ~/Notes/Notes --min-depth 1 --max-depth 1 --type d -L -E .Trash -E @Trash | fzf)"
            zle reset-prompt
          }
          zle -N jump_key_places

          # Setup preferred key bindings that emulate the parts of
          # emacs-style input manipulation that I'm familiar with
          bindkey '^P' up-history
          bindkey '^N' down-history
          bindkey '^?' backward-delete-char
          bindkey '^h' backward-delete-char
          bindkey '^w' backward-kill-word
          bindkey '\e^h' backward-kill-word
          bindkey '\e^?' backward-kill-word
          bindkey '^r' history-incremental-search-backward
          bindkey '^a' beginning-of-line
          bindkey '^e' end-of-line
          bindkey '\eb' backward-word
          bindkey '\ef' forward-word
          bindkey '^k' kill-line
          bindkey '^u' backward-kill-line
          bindkey '^f' jump_key_places

          # I prefer for up/down and j/k to do partial searches if there is
          # already text in play, rather than just normal through history
          bindkey '^[[A' up-line-or-search
          bindkey '^[[B' down-line-or-search
          bindkey -M vicmd 'k' up-line-or-search
          bindkey -M vicmd 'j' down-line-or-search
          bindkey '^r' history-incremental-search-backward
          bindkey '^s' history-incremental-search-forward

          # You might not like what I'm doing here, but '/' works like ctrl-r
          # and matches as you type. I've added pattern matches here though.

          bindkey -M vicmd '/' history-incremental-pattern-search-backward # default is vi-history-search-backward
          bindkey -M vicmd '?' vi-history-search-backward # default is vi-history-search-forward

          autoload -Uz edit-command-line
          zle -N edit-command-line
          bindkey -M vicmd 'v' edit-command-line

          # next line makes completions case insensitive
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
          zstyle ':completion:*' completer _extensions _complete _approximate
          zstyle ':completion:*' menu select
          zstyle ':completion:*:manuals'    separate-sections true
          zstyle ':completion:*:manuals.*'  insert-sections   true
          zstyle ':completion:*:man:*'      menu yes select
          zstyle ':completion:*' use-cache on
          zstyle ':completion:*' cache-path ~/.zsh/cache
          zstyle ':completion:*:(all-|)files' ignored-patterns '(|*/)CVS'
          #zstyle ':completion:*:cd:*' ignored-patterns '(*/)#CVS'
          zstyle ':completion:*:*:kill:*' menu yes select
          zstyle ':completion:*:kill:*'   force-list always
          zstyle -e ':completion:*:default' list-colors 'reply=("$''${PREFIX:+=(#bi)($PREFIX:t)(?)*==34=34}:''${(s.:.)LS_COLORS}")'

          zmodload -a colors
          zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS} # complete with same colors as ls
          zstyle ':completion:*:*:*:*:hosts' list-colors '=*=1;36' # bold cyan
          zstyle ':completion:*:*:*:*:users' list-colors '=*=36;40' # dark cyan on black

          setopt list_ambiguous

          zmodload -a autocomplete
          zmodload -a complist

          # Customize fzf plugin to use fd
          # Should default to ignore anything in ~/.gitignore
          #export FZF_DEFAULT_COMMAND='\fd --type f --hidden --exclude .git'
          # Use fd (https://github.com/sharkdp/fd) instead of the default find
          # command for listing path candidates.
          # - The first argument to the function ($1) is the base path to start traversal
          # - See the source code (completion.{bash,zsh}) for the details.
          # _fzf_compgen_path() {
          #   \fd --type d --hidden --follow --max-depth 3 --exclude .git . "$1"
          # }

          # Use fd to generate the list for directory completion
          # _fzf_compgen_dir() {
          #   \fd --type d --hidden --follow --max-depth 3 --exclude .git . "$1"
          # }


          # Per https://github.com/junegunn/fzf/wiki/Configuring-fuzzy-completion
          # Since fzf init comes before this, and we setopt vi, we need to reassign:
          #bindkey '^I' fzf-completion

          # Needed for lf to be pretty
          # . ~/.config/lf/lficons.sh

          if [[ -d /Applications/WezTerm.app/Contents/Resources ]] ; then source /Applications/WezTerm.app/Contents/Resources/wezterm.sh ; fi

          # Setup zoxide
          eval "$(zoxide init zsh)"

          precmd_functions+=(set_tab_title)

          function set_tab_title() {
              echo -ne "\033]0;zsh ($(basename "''${PWD/\/Users\/pwalsh/~}"))\007"
          }

          #### Change cursor depending on mode
          # following are needed with starship to get the cursors right
          # below versions are non-blinking; use 1,3,5 for blinking versions
          function _cursor_block() { echo -ne '\e[2 q' }
          function _cursor_bar() { echo -ne '\e[4 q' }
          function _cursor_beam() { echo -ne '\e[6 q' }
          function zle-line-finish {
              _cursor_block
          }
          function zle-keymap-select zle-line-init {
              case $KEYMAP in
                  vicmd)      _cursor_block;;
                  viins|main) _cursor_beam;;
                  *)          _cursor_bar;;
              esac
          }

          #### Make the up arrow default to just the local session commands, but ctrl-up can be global
          #bindkey "''${key [Up]}" up-line-or-local-history
          #bindkey "''${key [Down]}" down-line-or-local-history
          #bindkey "^[[1;5A" up-line-or-history    # [CTRL] + Cursor up
          #bindkey "^[[1;5B" down-line-or-history  # [CTRL] + Cursor down


          #up-line-or-local-history() {
              #zle set-local-history 1
              #zle up-line-or-history
              #zle set-local-history 0
          #}
          #zle -N up-line-or-local-history
          #down-line-or-local-history() {
              #zle set-local-history 1
              #zle down-line-or-history
              #zle set-local-history 0
          #}
          #zle -N down-line-or-local-history

          zle -N zle-line-init
          zle -N zle-line-finish
          zle -N zle-keymap-select

          #zprof
        '';
        sessionVariables = {};
        plugins = [
          {
            name = "zsh-nix-shell";
            file = "nix-shell.plugin.zsh";
            src = pkgs.fetchFromGitHub {
              owner = "chisui";
              repo = "zsh-nix-shell";
              rev = "v0.8.0";
              sha256 = "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7";
            };
          }
          {
            # better vi mode, see https://github.com/jeffreytse/zsh-vi-mode
            name = "zsh-vi-mode";
            file = "zsh-vi-mode.plugin.zsh";
            src = pkgs.zsh-vi-mode;
          }
        ];
        shellAliases =
          {
            c = "clear";
            ls = "eza --hyperlink --classify=always";
            l = "eza --icons --hyperlink --git-ignore --git --classify=always";
            la = "eza --icons --hyperlink --git-ignore --git --classify=always -a";
            ll = "eza --icons --hyperlink --git-ignore --git --classify=always -l";
            le = "eza --icons --hyperlink --git-ignore --git --classify=always --extended -l";
            lt = "eza --icons --hyperlink --git-ignore --git --classify=always -T";
            llt = "eza --icons --hyperlink --git-ignore --git --classify=always -l -T";
            lr = "eza -s oldest --git-ignore -F -l --hyperlink --color=always | head -30";
            fd = "\\fd -H -t d --hyperlink"; # default search directories
            f = "\\fd -H --hyperlink"; # default search this dir for files ignoring .gitignore etc
            fa = "\\fd -H -I -t f -t l --hyperlink"; # show all files and symlinks (including ignored and hidden)

            i = "iris"; # shortcut for iris digital assistant TODO: enable this once iris is installed properly
            #i = "nix run ~/src/personal/pwai --";
            iq = "fabric"; # this is like iris quick, but "IQ" works too and just shorter way to call fabric since "f" is taken
            iqp = "fabric -V Ollama -m gpt-oss:120b"; # this is like iris quick, but "IQ" works too and just shorter way to call fabric since "f" is taken
            it = "fabric --transcript -y"; # fetch a youtube video's transcript

            io = "opencode";

            #lf = "~/.config/lf/lfimg";
            nixflakeupdate1 = "nix run github:vimjoyer/nix-update-input"; # does `nix flake lock --update-input` with relevant fuzzy complete. Though actually, our tab completion does the same
            qp = ''
              qutebrowser --temp-basedir --set content.private_browsing true --set colors.tabs.bar.bg "#552222" --config-py "$HOME/.config/qutebrowser/config.py" --qt-arg name "qp,qp"'';
            calc = "kalker";
            df = "duf";
            # search for a note and with ctrl-n, create it if not found
            # add subdir as needed like "n meetings" or "n wiki"
            n = "zk edit --interactive";
            "pwdev-rust" = "nix develop ~/src/sideprojects/pwdev#rust";
            "pwdev-ts" = "nix develop ~/src/sideprojects/pwdev#ts";
            "pwdev-python" = "nix develop ~/src/sideprojects/pwdev#python";
            "pwdev-all" = "nix develop ~/src/sideprojects/pwdev#all";
            ".." = "cd ..";
            "..." = "cd ../..";
            "...." = "cd ../../..";
            # These options increase compatibility (with quicktime), but decrease resolution :(
            # when the mp4 resolution available is not the highest resolution available
            # -S '+vcodec:avc,+acodec:m4a'
            # -S 'codec:h264:m4a'
          }
          // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
            # Figure out the uniform type identifiers and uri schemes of a file (must specify the file)
            # for use in SwiftDefaultApps
            checktype = "mdls -name kMDItemContentType -name kMDItemContentTypeTree -name kMDItemKind";
            dwupdate = "pushd ~/.config/nixpkgs ; nix flake update ; popd ; dwswitchx ; dwshowupdates; popd";
            # Cachix on my whole nix store is burning unnecessary bandwidth and time -- slowing things down rather than speeding up
            # From now on will just use for select personal flakes and things
            #dwswitch = "pushd ~; cachix watch-exec zmre darwin-rebuild -- switch --flake ~/.config/nixpkgs/.#$(hostname -s) ; popd";
            dwswitchx = "pushd ~; sudo darwin-rebuild switch --flake ~/.config/nixpkgs/.#$(hostname -s) ; popd";
            dwclean = "pushd ~; sudo nix-env --delete-generations +7 --profile /nix/var/nix/profiles/system; sudo nix-collect-garbage --delete-older-than 30d ; nix store optimise ; popd";
            dwupcheck = "pushd ~/.config/nixpkgs ; nix flake update ; sudo darwin-rebuild build --flake ~/.config/nixpkgs/.#$(hostname -s) && nix store diff-closures /nix/var/nix/profiles/system ~/.config/nixpkgs/result; popd"; # todo: prefer nvd?
            # i use the zsh shell out in case anyone blindly copies this into their bash or fish profile since syntax is zsh specific
            dwshowupdates = ''
              zsh -c "nix store diff-closures /nix/var/nix/profiles/system-*-link(om[2]) /nix/var/nix/profiles/system-*-link(om[1])"'';
          }
          // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
            hmswitch = ''
              nix-shell -p home-manager --run "home-manager switch --flake ~/.config/nixpkgs/.#$(hostname -s)"'';
            noupdate = "pushd ~/.config/nixpkgs; nix flake update; popd; noswitch";
            noswitch = "pushd ~; sudo cachix watch-exec zmre nixos-rebuild -- switch --flake ~/.config/nixpkgs/.# ; popd";
          };
      };
    };

    home.file.".config/hn-tui.toml".text = ''
      [theme.palette]
      background = "#242424"
      foreground = "#f6f6ef"
      selection_background = "#4a4c4c"
      selection_foreground = "#d8dad6"
    '';

    home.sessionVariables = {
      NIX_PATH = "nixpkgs=${inputs.nixpkgs}:stable=${inputs.nixpkgs-stable}\${NIX_PATH:+:}$NIX_PATH";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      #TERM = "xterm-256color";
      KEYTIMEOUT = 1;
      EDITOR = "nvim";
      VISUAL = "nvim";
      GIT_EDITOR = "nvim";
      LS_COLORS = "no=00:fi=00:di=01;34:ln=35;40:pi=40;33:so=01;35:bd=40;33;01:cd=40;33;01:or=01;05;37;41:mi=01;05;37;41:ex=01;32:*.cmd=01;32:*.exe=01;32:*.com=01;32:*.btm=01;32:*.bat=01;32:";
      LSCOLORS = "ExfxcxdxCxegedabagacad";
      FIGNORE = "*.o:~:Application Scripts:CVS:.git";
      TZ = "America/Denver";
      LESS = "--raw-control-chars -FXRadeqs -P--Less--?e?x(Next file: %x):(END).:?pB%pB%.";
      CLICOLOR = 1;
      CLICOLOR_FORCE = "yes";
      PAGER = "page -WO -q 90000";
      # Add colors to man pages
      MANPAGER = "less -R --use-color -Dd+r -Du+b +Gg -M -s";
      SYSTEMD_COLORS = "true";
      COLORTERM = "truecolor";
      FZF_CTRL_R_OPTS = "--sort --exact";
      BROWSER = "qutebrowser";
      #TERMINAL = "kitty";
      HOMEBREW_NO_AUTO_UPDATE = 1;
      #LIBVA_DRIVER_NAME="iHD";
      # Where PAI is installed

      ZK_NOTEBOOK_DIR =
        if pkgs.stdenvNoCC.isDarwin
        then "/Users/${config.home.username}/Library/Mobile Documents/com~apple~CloudDocs/Notes"
        else "/home/${config.home.username}/Notes";
    };
  };
}
