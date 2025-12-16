{
  flake.modules.homeManager.atuin = {
    # Nice shell history https://atuin.sh -- experimenting with this 2024-07-26
    programs.atuin = {
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
  };
}
