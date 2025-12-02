{inputs, ...}: {
  flake.modules.homeManager.tmux = {pkgs, ...}: {
    home.file.".terminfo/74/tmux-256color".source =
      ../../../dotfiles/terminfo/74/tmux-256color;
    programs.tmux = {
      enable = true;
      keyMode = "vi";
      mouse = true;
      newSession = true;
      shell = "${pkgs.zsh}/bin/zsh";
      historyLimit = 10000;
      escapeTime = 0;
      extraConfig = builtins.readFile ../../../dotfiles/tmux.conf;
      sensibleOnTop = true;
      plugins = with pkgs; [
        tmuxPlugins.sensible
        tmuxPlugins.open
      ];
    };
  };
}
