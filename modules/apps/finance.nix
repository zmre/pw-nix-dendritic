{inputs, ...}: {
  # ldash: portfolio-tracking / budgeting TUI for hledger (Rust, Codeberg).
  # Not on crates.io or nixpkgs; build from source pinned to a release tag.
  flake-file.inputs.ldash-src = {
    url = "git+https://codeberg.org/md-weber/ldash?ref=refs/tags/v1.3.1";
    flake = false;
  };

  flake.modules.homeManager.finance = {
    pkgs,
    lib,
    ...
  }: let
    ldash = pkgs.rustPlatform.buildRustPackage {
      pname = "ldash";
      version = "1.3.1";
      src = inputs.ldash-src;
      cargoLock.lockFile = inputs.ldash-src + /Cargo.lock;
      # Snapshot (insta) tests aren't needed to install the binary.
      doCheck = false;
      buildInputs =
        lib.optionals pkgs.stdenv.isDarwin [pkgs.libiconv pkgs.apple-sdk];
      meta.mainProgram = "ldash";
    };
  in {
    home.sessionVariables = {
      "LEDGER_FILE" = "$HOME/Sync/Private/Finances/Ledger/main.journal"; # used by ldash
    };
    home.packages = with pkgs; [
      hledger # core CLI: plain-text double-entry accounting
      hledger-ui # terminal UI
      hledger-web # web UI
      hledger-iadd # interactive `add` replacement (TUI)
      hledger-fmt # opinionated journal formatter
      hledger-utils # grab-bag of extra hledger utilities
      puffin # terminal dashboard for hledger
      ldash # portfolio / budget TUI
      pricehist # fetch portfolio price histories
    ];
  };
}
