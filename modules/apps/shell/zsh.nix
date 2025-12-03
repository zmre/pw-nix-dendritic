{inputs, ...}: {
  flake.modules.homeManager.zsh = {
    pkgs,
    lib,
    ...
  }: {
    programs.zsh = {
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
          dwupdate = "pushd ~/src/pw-nix-dendritic ; nix flake update ; popd ; dwswitchx ; dwshowupdates; popd";
          # Cachix on my whole nix store is burning unnecessary bandwidth and time -- slowing things down rather than speeding up
          # From now on will just use for select personal flakes and things
          #dwswitch = "pushd ~; cachix watch-exec zmre darwin-rebuild -- switch --flake ~/.config/nixpkgs/.#$(hostname -s) ; popd";
          dwswitchx = "pushd ~/src/pw-nix-dendritic; sudo darwin-rebuild switch --flake ~/src/pw-nix-dendritic/.#$(hostname -s) ; popd";
          dwclean = "pushd ~; sudo nix-env --delete-generations +7 --profile /nix/var/nix/profiles/system; sudo nix-collect-garbage --delete-older-than 30d ; nix store optimise ; popd";
          dwupcheck = "pushd ~/src/pw-nix-dendritic ; nix flake update ; sudo darwin-rebuild build --flake ~/src/pw-nix-dendritic.#$(hostname -s) && nix store diff-closures /nix/var/nix/profiles/system ~/src/pw-nix-dendritic/result; popd"; # todo: prefer nvd?
          # i use the zsh shell out in case anyone blindly copies this into their bash or fish profile since syntax is zsh specific
          dwshowupdates = ''
            zsh -c "nix store diff-closures /nix/var/nix/profiles/system-*-link(om[2]) /nix/var/nix/profiles/system-*-link(om[1])"'';
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          hmswitch = "home-manager switch --flake ~/src/pw-nix-dendritic/.#$(hostname -s) --show-trace";
          hmupdate = "pushd ~/src/pw-nix-dendritic ; nix flake update ; popd ; hmswitch";
          noupdate = "pushd ~/src/pw-nix-dendritic; nix flake update; popd; noswitch";
          noswitch = "pushd ~/src/pw-nix-dendritic; sudo nixos-rebuild switch --flake .# ; popd";
        };
    };
  };
}
