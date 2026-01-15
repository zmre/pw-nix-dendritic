{
  flake.darwinModules.dev-gui = {
    homebrew.casks = [
      "dash" # offline developer docs
      "fork"
      "gitkraken-cli"
    ];
    homebrew.masApps = {
      "Kaleidoscope" = 587512244; # GUI 3-way merge
      "Xcode" = 497799835;
    };
  };

  flake.modules.homeManager.dev-gui = {
    pkgs,
    lib,
    ...
  }: let
    inherit (pkgs.stdenvNoCC.hostPlatform) system;
  in {
    # VSCode whines like a ... I don't know, but a lot when the config file is read-only
    # I want nix to govern the configs, but to let vscode edit it (ephemerally) if I change
    # the zoom or whatever. This hack just copies the symlink to a normal file
    home.activation.vscodeWritableConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      code_dir="$(echo ~/Library)/Application Support/Code/User"
      settings="$code_dir/settings.json"
      settings_nix="$code_dir/settings.nix.json"
      settings_bak="$settings.bak"

      if [ -f "$settings" ] ; then
        echo "activating $settings"

        $DRY_RUN_CMD mv "$settings" "$settings_nix"
        $DRY_RUN_CMD cp -H "$settings_nix" "$settings"
        $DRY_RUN_CMD chmod u+w "$settings"
        $DRY_RUN_CMD rm -f "$settings_bak"
      fi
    '';

    programs = {
      vscode = {
        enable = true;
        mutableExtensionsDir =
          true; # to allow vscode to install extensions not available via nix
        # package = pkgs.vscode-fhs; # or pkgs.vscodium or pkgs.vscode-with-extensions
        profiles.default = {
          extensions = with pkgs.vscode-extensions; [
            bbenoist.nix
            scala-lang.scala
            svelte.svelte-vscode
            mkhl.direnv
            redhat.vscode-yaml
            jnoortheen.nix-ide
            vspacecode.whichkey # ?
            tamasfe.even-better-toml
            #ms-python.python # disabled 2025-03-08 due to hash mismatch
            ms-toolsai.jupyter
            ms-toolsai.jupyter-keymap
            ms-toolsai.jupyter-renderers
            ms-toolsai.vscode-jupyter-cell-tags
            ms-toolsai.vscode-jupyter-slideshow
            esbenp.prettier-vscode
            timonwong.shellcheck
            # rust-lang.rust-analyzer # disabled 2025-02-21 due to build failure
            graphql.vscode-graphql
            dbaeumer.vscode-eslint
            codezombiech.gitignore
            bierner.markdown-emoji
            bradlc.vscode-tailwindcss
            naumovs.color-highlight
            mikestead.dotenv
            mskelton.one-dark-theme
            prisma.prisma
            asvetliakov.vscode-neovim
            brettm12345.nixfmt-vscode
            davidanson.vscode-markdownlint
            pkief.material-icon-theme
            dracula-theme.theme-dracula
            #eamodio.gitlens # for git blame
            marp-team.marp-vscode # for markdown slides
            #pkgs.kubernetes-yaml-formatter # format k8s; from overlays and flake input # not building as of 2024-04-22; not sure why, no time to debug right now
            # live share not currently working via nix
            #ms-vsliveshare.vsliveshare # live share coding with others
            # wishlist
            # ardenivanov.svelte-intellisense
            # cschleiden.vscode-github-actions
            github.vscode-github-actions
            # csstools.postcss
            # stylelint.vscode-stylelint
            # vunguyentuan.vscode-css-variables
            # ZixuanChen.vitest-explorer
            # bettercomments ?
          ];
          # starting point for bindings: https://github.com/LunarVim/LunarVim/blob/4625145d0278d4a039e55c433af9916d93e7846a/utils/vscode_config/keybindings.json
          keybindings = [
            {
              "key" = "ctrl+e";
              "command" = "workbench.view.explorer";
            }
            {
              "key" = "shift+ctrl+e";
              "command" = "-workbench.view.explorer";
            }
          ];
          userSettings = {
            # Much of the following adapted from https://github.com/LunarVim/LunarVim/blob/4625145d0278d4a039e55c433af9916d93e7846a/utils/vscode_config/settings.json
            "editor.tabSize" = 2;
            "editor.fontLigatures" = true;
            "editor.guides.indentation" = false;
            "editor.insertSpaces" = true;
            "editor.fontFamily" = "'Hasklug Nerd Font', 'JetBrainsMono Nerd Font', 'FiraCode Nerd Font','SF Mono', Menlo, Monaco, 'Courier New', monospace";
            "editor.fontSize" = 12;
            "editor.formatOnSave" = true;
            "editor.suggestSelection" = "first";
            "editor.scrollbar.horizontal" = "hidden";
            "editor.scrollbar.vertical" = "hidden";
            "editor.scrollBeyondLastLine" = false;
            "editor.cursorBlinking" = "solid";
            "editor.minimap.enabled" = false;
            "[nix]"."editor.tabSize" = 2;
            "[svelte]"."editor.defaultFormatter" = "svelte.svelte-vscode";
            "[jsonc]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
            "extensions.ignoreRecommendations" = false;
            "files.insertFinalNewline" = true;
            "[scala]"."editor.tabSize" = 2;
            "[json]"."editor.tabSize" = 2;
            "vim.highlightedyank.enable" = true;
            "files.trimTrailingWhitespace" = true;
            #"gitlens.codeLens.enabled" = false;
            #"gitlens.currentLine.enabled" = false;
            #"gitlens.hovers.currentLine.over" = "line";
            "vsintellicode.modify.editor.suggestSelection" = "automaticallyOverrodeDefaultValue";
            "java.semanticHighlighting.enabled" = true;
            "workbench.editor.showTabs" = true;
            "workbench.list.automaticKeyboardNavigation" = false;
            "workbench.activityBar.visible" = false;
            #"workbench.colorTheme" = "Dracula";
            "workbench.colorTheme" = "One Dark";
            "workbench.iconTheme" = "material-icon-theme";
            "editor.accessibilitySupport" = "off";
            "oneDark.bold" = true;
            "window.zoomLevel" = 1;
            "window.menuBarVisibility" = "toggle";
            #"terminal.integrated.shell.linux" = "${pkgs.zsh}/bin/zsh";

            "svelte.enable-ts-plugin" = true;
            "javascript.inlayHints.functionLikeReturnTypes.enabled" = true;
            "javascript.referencesCodeLens.enabled" = true;
            "javascript.suggest.completeFunctionCalls" = true;

            "vscode-neovim.neovimExecutablePaths.darwin" = "${pkgs.neovim}/bin/nvim";
            "vscode-neovim.neovimExecutablePaths.linux" = "${pkgs.neovim}/bin/nvim";
            /*
            "vscode-neovim.neovimInitVimPaths.darwin" = "$HOME/.config/nvim/init.vim";
            "vscode-neovim.neovimInitVimPaths.linux" = "$HOME/.config/nvim/init.vim";
            */
            "editor.tokenColorCustomizations" = {
              "textMateRules" = [
                {
                  "name" = "One Dark bold";
                  "scope" = [
                    "entity.name.function"
                    "entity.name.type.class"
                    "entity.name.type.module"
                    "entity.name.type.namespace"
                    "keyword.other.important"
                  ];
                  "settings" = {"fontStyle" = "bold";};
                }
                {
                  "name" = "One Dark italic";
                  "scope" = [
                    "comment"
                    "entity.other.attribute-name"
                    "keyword"
                    "markup.underline.link"
                    "storage.modifier"
                    "storage.type"
                    "string.url"
                    "variable.language.super"
                    "variable.language.this"
                  ];
                  "settings" = {"fontStyle" = "italic";};
                }
                {
                  "name" = "One Dark italic reset";
                  "scope" = [
                    "keyword.operator"
                    "keyword.other.type"
                    "storage.modifier.import"
                    "storage.modifier.package"
                    "storage.type.built-in"
                    "storage.type.function.arrow"
                    "storage.type.generic"
                    "storage.type.java"
                    "storage.type.primitive"
                  ];
                  "settings" = {"fontStyle" = "";};
                }
                {
                  "name" = "One Dark bold italic";
                  "scope" = ["keyword.other.important"];
                  "settings" = {"fontStyle" = "bold italic";};
                }
              ];
            };
          };
        };
      };

      zed-editor = {
        enable = true; # 2025-07-02 disable until https://github.com/nix-community/home-manager/issues/7327 is resolved
        #package = pkgs.stable.zed-editor; # takes forever to build so sticking to recent stable
        # added the zed cachix so this should be better now
        extensions = [
          "catpuccin"
          "csv"
          "graphql"
          "java"
          "log"
          "lua"
          "cargo-tom"
          "nix"
          "make"
          "marksman"
          "mermaid"
          "onedark-pro"
          "onedark-extended"
          "pest"
          "prisma"
          "pylsp"
          "scala"
          "scss"
          "svelte"
          "tailwind-theme"
          "html"
        ];
        extraPackages = with pkgs; [
          fd
          ripgrep
          fzy
          zoxide
          bat # previewer for telescope for now
          zk # lsp for markdown notes in zk folders
          #markdown-oxide # lsp for any markdown
          marksman # lsp for any markdown
          zsh # terminal requires it
          git
          curl # needed to fetch titles from urls
          # todo: research https://github.com/artempyanykh/marksman
          vale # linter for prose
          proselint # ditto
          luaformatter # ditto for lua
          #prisma-engines # ditto for schema.prisma files # TODO: bring back when rust compile issues are fixed 2024-08-26
          # Nix language servers summary 2023-11-23
          # rnix-lsp -- seems abandoned
          # nil -- way better than rnix and generally great, but
          stable.nixd # -- damn good at completions referencing back to nixpkgs, for example
          #         at least provided you do some weird gymnastics in flakes:
          #         https://github.com/nix-community/nixd/blob/main/docs/user-guide.md#faq
          #         using this one for now
          #nixfmt # nix formatter
          alejandra # better nix formatter alternative
          statix # linter for nix
          shellcheck
          languagetool # needed by grammarous, but must be v5.9 (see overlay)
          # luajitPackages.lua-lsp
          lua-language-server
          pyright # python lsp (written in node? so weird)
          vscode-langservers-extracted # lsp servers for json, html, css, eslint
          nodePackages.eslint_d # js/ts code formatter and linter
          nodePackages.prettier # ditto
          #nodePackages.prisma # dependency prisma-engines not compiling right now 2024-08-26
          nodePackages.svelte-language-server
          nodePackages.diagnostic-languageserver
          nodePackages.typescript-language-server
          nodePackages.bash-language-server
          nodePackages."@tailwindcss/language-server"
          #nodePackages_latest.grammarly-languageserver # besides being a privacy issue if triggered, we have these issues:
          # https://github.com/znck/grammarly/issues/411 grammarly sdk deprecated
          # https://github.com/NixOS/nixpkgs/issues/293172 requires node16, which is EOL
          yaml-language-server
          # jinja-lsp # jinja is an html template language; i'm using zola right now which uses the tera language, which is a lot like jinja
          mypy # static typing for python used by null-ls
          ruff # python linter used by null-ls
          black # python formatter
          rust-analyzer # lsp for rust
          clippy
          # rust-analyzer is currently in a partially broken state as it cannot find rust sources so can't
          # help with native language things, which sucks. Here are some issues to track:
          # https://github.com/rust-lang/rust/issues/95736 - FIXED
          # https://github.com/rust-lang/rust-analyzer/issues/13393 - CLOSED NOT RESOLVED
          # https://github.com/mozilla/nixpkgs-mozilla/issues/238
          #                     - suggestion to do export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src" which is like what we're doing below in customRC, I think
          # https://github.com/rust-lang/cargo/issues/10096
          rustfmt
          cargo # have this as a fallback when a local flake isn't in place
          rustc # have this as a fallback when a local flake isn't in place
          vscode-extensions.vadimcn.vscode-lldb.adapter # for debugging rust
          (python3.withPackages (ps: with ps; [debugpy])) # required for debugging python, but better if that's per project installed since we don't have python

          metals # lsp for scala
        ];
        # userKeymaps = {};
        userSettings = {
          vim_mode = true;
          load_direnv = "shell_hook";
          tabs = {
            "git_status" = true;
            "code_actions" = true;
          };
          toolbar = {
            "code_actions" = true;
            "agent_review" = true;
            "quick_actions" = true;
          };
          diagnostics = {
            include_warnings = true;
            inline = {
              enabled = false;
            };
          };
          git = {
            inline_blame = {
              enabled = false;
            };
          };
          inlay_hints = {
            enabled = true;
            show_type_hints = true;
            show_parameter_hint = true;
            show_other_hints = true;
          };
          telemetry = {
            metrics = false;
          };
          features = {
            copilot = true;
          };
          ui_font_size = 16;
          buffer_font_size = 16;
          theme = {
            mode = "system";
            light = "One Light";
            dark = "One Dark";
          };
          terminal = {
            font_family = "MesloLGS Nerd Font";
          };
          lsp = {
            "rust-analyzer" = {
              "initialization_options" = {
                check = {
                  # default of "cargo check" just shows compile errors while "cargo clippy" gives other code advice that's useful
                  command = "clippy"; # rust-analyzer.check.command (default: "check")
                };
              };
            };
          };
        };
      };
    };
  };
}
