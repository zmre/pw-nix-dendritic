{inputs, ...}: {
  flake-file.inputs.pwnvim.url = "github:zmre/pwnvim";
  flake-file.inputs.pwneovide.url = "github:zmre/pwneovide";
  flake-file.inputs.pwneovide.inputs.pwnvim.follows = "pwnvim";

  flake.modules.homeManager.vim-gui = {
    pkgs,
    lib,
    ...
  }: let
    system = pkgs.stdenvNoCC.hostPlatform.system;
  in {
    home.packages = [
      inputs.pwneovide.packages.${system}.default
    ];
  };

  flake.modules.homeManager.vim = {
    pkgs,
    lib,
    ...
  }: let
    system = pkgs.stdenvNoCC.hostPlatform.system;
  in {
    home.packages = [
      inputs.pwnvim.packages.${system}.default
    ];
    programs = {
      zsh.defaultKeymap = "viins";
      nushell.settings.edit_mode = "vi";
    };
    programs.zsh.initContent = lib.mkBefore ''
      #zmodload zsh/zprof
      set -o vi
      bindkey -v

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


    '';

    home.file.".inputrc".text = ''
      set show-all-if-ambiguous on
      set completion-ignore-case on
      set mark-directories on
      set mark-symlinked-directories on

      # Do not autocomplete hidden files unless the pattern explicitly begins with a dot
      set match-hidden-files off

      # Show extra file information when completing, like `ls -F` does
      set visible-stats on

      # Be more intelligent when autocompleting by also looking at the text after
      # the cursor. For example, when the current line is "cd ~/src/mozil", and
      # the cursor is on the "z", pressing Tab will not autocomplete it to "cd
      # ~/src/mozillail", but to "cd ~/src/mozilla". (This is supported by the
      # Readline used by Bash 4.)
      set skip-completed-text on

      # Allow UTF-8 input and output, instead of showing stuff like $'\0123\0456'
      set input-meta on
      set output-meta on
      set convert-meta off

      # Use Alt/Meta + Delete to delete the preceding word
      "\e[3;3~": kill-word

      set keymap vi
      set editing-mode vi-insert
      "\e\C-h": backward-kill-word
      "\e\C-?": backward-kill-word
      "\eb": backward-word
      "\C-a": beginning-of-line
      "\C-l": clear-screen
      "\C-e": end-of-line
      "\ef": forward-word
      "\C-k": kill-line
      "\C-y": yank
      # Go up a dir with ctrl-n
      "\C-n":"cd ..\n"
      set editing-mode vi
      set show-mode-in-prompt on
      # non-blinking block cursor when in normal mode
      set vi-cmd-mode-string "\1\e[2 q\2"
      # non-blinking beam cursor when in insert mode
      set vi-ins-mode-string "\1\e[6 q\2"
    '';
  };
}
