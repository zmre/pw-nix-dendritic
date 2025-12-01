{inputs, ...}: {
  # github extensions not in nixpkgs (should periodically check that)
  flake-file.inputs.gh-worktree.url = "github:zmre/gh-worktree";
  flake-file.inputs.gh-worktree.inputs.nixpkgs.follows = "nixpkgs";
  flake-file.inputs.gh-feed.url = "github:rsteube/gh-feed";
  flake-file.inputs.gh-feed.flake = false;

  flake.modules.homeManager.dev = {
    pkgs,
    lib,
    ...
  }: let
    system = pkgs.stdenvNoCC.hostPlatform.system;

    gh-feed = pkgs.buildGoModule {
      pname = "gh-feed";
      name = "gh-feed";
      doCheck = false;
      src = inputs.gh-feed;
      # just have to manually update this each time it fails, I guess
      # vendorHash = prev.lib.fakeHash;
      vendorHash = "sha256-RtEHikMR+oQreo3Uv1om79RTPYOfVrL2kNOrD4jC5to=";
    };
  in {
    home.packages = with pkgs; [
      # file viewers
      less
      page # like less, but uses nvim, which is handy for selecting out text and such
      file
      jq
      lynx
      sourceHighlight # for lf preview
      ffmpeg-full.bin
      ffmpegthumbnailer # for lf preview
      pandoc # for lf preview
      imagemagick # for lf preview
      highlight # code coloring in lf
      poppler-utils # for pdf2text in lf
      mediainfo # used by lf
      exiftool # used by lf
      #rich-cli # used by lf (experimenting with mdcat replacement)
      exif
      glow # browse markdown dirs
      mdcat # colorize markdown
      html2text
      colima
      docker
    ];
    programs = {
      git = {
        enable = true;
        lfs.enable = true;
        settings =
          {
            user = {
              name = "Patrick Walsh";
              email = "patrick.walsh@ironcorelabs.com";
            };
            alias = {
              gone = ''
                ! git fetch -p && git for-each-ref --format '%(refname:short) %(upstream:track)' | awk '$2 == "[gone]" {print $1}' | xargs -r git branch -D'';
              tatus = "status";
              co = "checkout";
              br = "branch";
              st = "status -sb";
              wtf = "!git-wtf";
              lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --topo-order --date=relative";
              gl = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --topo-order --date=relative";
              lp = "log -p";
              lr = "reflog";
              ls = "ls-files";
              dall = "diff";
              d = "diff --relative";
              dv = "difftool";
              df = "diff --relative --name-only";
              dvf = "difftool --relative --name-only";
              dfall = "diff --name-only";
              ds = "diff --relative --name-status";
              dvs = "difftool --relative --name-status";
              dsall = "diff --name-status";
              dvsall = "difftool --name-status";
              dr = "diff-index --cached --name-only --relative HEAD";
              di = "diff-index --cached --patch --relative HEAD";
              dfi = "diff-index --cached --name-only --relative HEAD";
              subpull = "submodule foreach git pull";
              subco = "submodule foreach git checkout master";
            };
            github.user = "zmre";
            color.ui = true;
            pull.rebase = true;
            merge.conflictstyle = "diff3";
            init.defaultBranch = "main";
            http.sslVerify = true;
            commit.verbose = true;
            credential.helper =
              if pkgs.stdenvNoCC.isDarwin
              then "osxkeychain"
              else "cache --timeout=10000000";
            diff.algorithm = "patience";
            protocol.version = "2";
            core.commitGraph = true;
            gc.writeCommitGraph = true;
            push.autoSetupRemote = true;
          }
          // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
            # these should speed up vim nvim-tree and other things that watch git repos but
            # only works on mac. see https://github.com/nvim-tree/nvim-tree.lua/wiki/Troubleshooting#git-fsmonitor-daemon
            core.fsmonitor = true;
            core.untrackedcache = true;
          };
        ignores = import ../../dotfiles/gitignore.nix;
      };
      # intelligent diffs that are syntax parse tree aware per language in git
      difftastic = {
        enable = true;
        git.enable = true;
        options.background = "dark";
        # color = "always";
      };
      # Really nice looking diffs
      delta = {
        enable = false;
        # git.enable = true;
        options = {
          syntax-theme = "Monokai Extended";
          line-numbers = true;
          navigate = true;
          side-by-side = true;
        };
      };
      gh = {
        enable = true;
        package = pkgs.gh;
        # Ones I have installed that aren't available in pkgs 2024-07-31:
        #inputs.gh-feed
        extensions = with pkgs; [gh-dash gh-notify gh-poi inputs.gh-worktree.packages.${system}.gh-worktree gh-feed gh-s gh-i];
        settings = {git_protocol = "ssh";};
      };
    };
  };
}
