{
  flake.darwinModules.term-gui = {pkgs, ...}: {
    homebrew.casks = [
      "ghostty" # available in nixos only for linux
      "wezterm"
    ];
  };
  flake.modules.homeManager.term-gui = {pkgs, ...}: {
    home.file.".wezterm.lua".source = ../../dotfiles/wezterm/wezterm.lua;
    programs.kitty = {
      enable = false;
      #package = pkgs.emptyDirectory; # post 15.1 update, having issues with nix version and moving to brew for now 2024-10-30
      keybindings = {
        "super+equal" = "increase_font_size";
        "super+minus" = "decrease_font_size";
        "super+0" = "restore_font_size";
        "cmd+c" = "copy_to_clipboard";
        "cmd+v" = "paste_from_clipboard";
        # cmd-[ and cmd-] switch tmux windows
        # \x02 is ctrl-b so sequence below is ctrl-b, h
        "cmd+[" = "send_text all \\x02h";
        "cmd+]" = "send_text all \\x02l";
        "ctrl+shift+b" = "show_scrollback";
        # "ctrl+shift+b" = "launch --stdin-source=@screen_scrollback --stdin-add-formatting --type=overlay page -WO -q 90000";
        "ctrl+shift+h" = "neighboring_window left";
        "ctrl+shift+j" = "neighboring_window down";
        "ctrl+shift+k" = "neighboring_window up";
        "ctrl+shift+l" = "neighboring_window right";
        "ctrl+shift+m" = "next_layout";
        "cmd+1" = "goto_tab 1";
        "cmd+2" = "goto_tab 2";
        "cmd+3" = "goto_tab 3";
        "cmd+4" = "goto_tab 4";
        "cmd+5" = "goto_tab 5";
        "cmd+6" = "goto_tab 6";
        "cmd+7" = "goto_tab 7";
        "cmd+8" = "goto_tab 8";
        "cmd+9" = "goto_tab 9";
        "cmd+alt+1" = "first_window";
        "cmd+alt+2" = "second_window";
        "cmd+alt+3" = "third_window";
        "cmd+alt+4" = "fourth_window";
        "cmd+alt+5" = "fifth_window";
        "cmd+alt+6" = "sixth_window";
        "cmd+alt+7" = "seventh_window";
        "cmd+alt+8" = "eighth_window";
        "cmd+alt+9" = "ninth_window";
      };
      font = {
        name = "Hasklug Nerd Font Mono Medium";
        #name = "Hasklug Nerd Font Medium"; # regular is too thin
        #name = "Inconsolata Nerd Font"; # no italic
        #name = "SpaceMono Nerd Font Mono";
        #name = "VictorMono Nerd Font";
        #name = "FiraCode Nerd Font"; # missing italic
        size =
          if pkgs.stdenvNoCC.isDarwin
          then 17
          else 12;
      };
      darwinLaunchOptions = ["--single-instance"];
      settings = {
        scrollback_lines = 10000;
        # scrollback_pager = "nvim -u NONE -R -M -c 'lua require(\"pwnvim.kitty+page\")(INPUT_LINE_NUMBER, CURSOR_LINE, CURSOR_COLUMN)' -";
        # scrollback_pager = "page -WO -q 90000";
        # map f1
        # scrollback_pager = "nvim -R -M -";
        scrollback_pager = ''nvim -R -c "set norelativenumber nonumber nolist signcolumn=no showtabline=0 foldcolumn=0" -c "autocmd TermOpen * normal G" -c "autocmd TermClose * :!rm /tmp/kitty_scrollback_buffer" -c "silent! write /tmp/kitty_scrollback_buffer | terminal cat /tmp/kitty_scrollback_buffer -"'';
        enable_audio_bell = false;
        update_check_interval = 0;
        macos_option_as_alt = "both";
        macos_quit_when_last_window_closed = true;
        adjust_line_height = "105%";
        disable_ligatures = "cursor"; # disable ligatures when cursor is on them
        shell_integration = "enabled";

        # Fonts
        bold_font = "Hasklug Nerd Font Mono Bold"; # "auto";
        italic_font = "Hasklug Nerd Font Mono Italic";
        bold_italic_font = "Hasklug Nerd Font Mono Bold Italic";

        # Window layout
        #hide_window_decorations = "titlebar-only";
        window_padding_width = "5";
        macos_show_window_title_in = "window";

        # Tab bar
        tab_bar_edge = "bottom";
        tab_bar_style = "powerline";
        tab_title_template = "{title}"; # "{index}: {title}";

        # Colors
        active_tab_font_style = "bold";
        inactive_tab_font_style = "normal";
        active_tab_foreground = "#ffffff";
        active_tab_background = "#2233ff";
        tab_activity_symbol = " ";

        # Misc
        # nvim true-zen kitty integration requires following two settings, but I've disabled due to bugs in true-zen
        allow_remote_control = "socket-only";
        listen_on = "unix:/tmp/kitty-sock";
        visual_bell_duration = "0.1";
        background_opacity = "0.95";
        startup_session = "~/.config/kitty/startup.session";
        shell = "${pkgs.zsh}/bin/zsh --login --interactive";
      };
      themeFile = "OneHalfDark"; # or Dracula or OneDark see https://github.com/kovidgoyal/kitty-themes/tree/master/themes
      # extraConfig = "\n";
    };
    programs.alacritty = {
      enable = pkgs.stdenv.isLinux; # only install on Linux
      #package =
      #pkgs.alacritty; # switching to unstable so i get 0.11 with undercurl support
      settings = {
        window.decorations = "full";
        window.dynamic_title = true;
        #background_opacity = 0.9;
        window.opacity = 0.9;
        scrolling.history = 3000;
        # scrolling.smooth = true;
        font.normal.family = "MesloLGS Nerd Font Mono";
        font.normal.style = "Regular";
        font.bold.style = "Bold";
        font.italic.style = "Italic";
        font.bold_italic.style = "Bold Italic";
        font.size =
          if pkgs.stdenvNoCC.isDarwin
          then 16
          else 9;
        shell.program = "${pkgs.zsh}/bin/zsh";
        live_config_reload = true;
        cursor.vi_mode_style = "Underline";
        colors.draw_bold_text_with_bright_colors = true;
        keyboard.bindings = [
          {
            key = "Escape";
            mods = "Control";
            mode = "~Search";
            action = "ToggleViMode";
          }
          # cmd-{ and cmd-} and cmd-] and cmd-[ will switch tmux windows
          # {
          #   key = "LBracket";
          #   mods = "Command";
          #   # \x02 is ctrl-b so sequence below is ctrl-b, h
          #   chars = "\\x02h";
          # }
          # {
          #   key = "RBracket";
          #   mods = "Command";
          #   chars = "\\x02l";
          # }
        ];
      };
    };
  };
}
