{inputs, ...}: {
  flake.modules.homeManager.shell = {
    pkgs,
    lib,
    config,
    ...
  }: {
    imports = with inputs.self.modules.homeManager; [
      atuin
      hackernews-tui
      starship
      tmux
      zsh
    ];
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
      bash = {
        enable = true;
        shellAliases = {
          ll = "ls -lah";
          rebuild = "sudo nixos-rebuild switch --flake /etc/nixos";
        };
      };
      direnv = {
        enable = true;
        enableZshIntegration = true;
        enableNushellIntegration = true;
        nix-direnv.enable = true;
      };
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
      zoxide = {
        enable = true;
        enableZshIntegration = true;
        enableNushellIntegration = false;
      };
    };

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
