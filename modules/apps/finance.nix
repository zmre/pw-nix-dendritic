{inputs, ...}: {
  # ldash: portfolio-tracking / budgeting TUI for hledger (Rust, Codeberg).
  # Not on crates.io or nixpkgs; build from source pinned to a release tag.
  flake-file.inputs.ldash-src = {
    url = "git+https://codeberg.org/md-weber/ldash?ref=refs/tags/v1.3.1";
    flake = false;
  };

  # accountant24: free, local-first AI agent for personal finance.
  # Upstream ships self-contained per-platform binaries (Bun-compiled) with
  # sidecar assets; we fetch the prebuilt darwin/arm64 release as a raw file
  # and wrap it so hledger/poppler/tesseract are on PATH at runtime.
  flake-file.inputs.accountant24-bin = {
    url = "https://github.com/machulav/accountant24/releases/download/v0.1.10/accountant24-darwin-arm64.tar.gz";
    type = "file";
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

    # darwin/aarch64 only -- the only prebuilt artifact we wire up, and velaris
    # (aarch64-darwin) is the sole consumer.
    accountant24 = pkgs.stdenvNoCC.mkDerivation {
      pname = "accountant24";
      version = "0.1.10";
      src = inputs.accountant24-bin;
      nativeBuildInputs = [pkgs.makeWrapper];
      unpackPhase = ''
        runHook preUnpack
        mkdir -p unpacked
        tar xzf $src -C unpacked
        runHook postUnpack
      '';
      sourceRoot = "unpacked";
      installPhase = ''
        runHook preInstall
        mkdir -p $out/libexec/accountant24 $out/bin
        cp -R . $out/libexec/accountant24/
        chmod +x $out/libexec/accountant24/accountant24
        makeWrapper $out/libexec/accountant24/accountant24 $out/bin/accountant24 \
          --prefix PATH : ${lib.makeBinPath [pkgs.hledger pkgs.poppler-utils pkgs.tesseract]}
        ln -s $out/bin/accountant24 $out/bin/a24
        runHook postInstall
      '';
      meta.mainProgram = "accountant24";
    };
  in {
    home.packages = with pkgs;
      [
        hledger # core CLI: plain-text double-entry accounting
        hledger-ui # terminal UI
        hledger-web # web UI
        hledger-iadd # interactive `add` replacement (TUI)
        hledger-fmt # opinionated journal formatter
        hledger-utils # grab-bag of extra hledger utilities
        puffin # terminal dashboard for hledger
        ldash # portfolio / budget TUI
      ]
      ++ lib.optionals (pkgs.stdenv.isDarwin && pkgs.stdenv.hostPlatform.isAarch64) [
        accountant24 # local-first AI finance agent (`a24`)
      ];
  };
}
