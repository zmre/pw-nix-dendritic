{inputs, ...}: {
  # Ledgera: cross-platform Tauri/Rust GUI for hledger.
  # Not in nixpkgs and no Homebrew cask exists; upstream ships an unsigned
  # prebuilt macOS .app. Fetch the zipped bundle as a raw file and unpack it so
  # home-manager's copyApps drops Ledgera.app into ~/Applications.
  # NOTE: the build is unsigned/not-notarized -- on first launch use
  # right-click -> Open (or `xattr -dr com.apple.quarantine` on the .app).
  flake-file.inputs.ledgera-macos-app = {
    url = "https://github.com/thesmokinator/ledgera/releases/download/v0.1.5/Ledgera-v0.1.5-macos-app.zip";
    type = "file";
    flake = false;
  };

  # Kept as a slot for any future Homebrew casks under this feature.
  flake.darwinModules.finance-gui = {
    homebrew.casks = [];
  };

  flake.modules.homeManager.finance-gui = {
    pkgs,
    lib,
    ...
  }: let
    ledgera = pkgs.stdenvNoCC.mkDerivation {
      pname = "ledgera";
      version = "0.1.5";
      src = inputs.ledgera-macos-app;
      nativeBuildInputs = [pkgs.unzip];
      unpackPhase = ''
        runHook preUnpack
        mkdir -p unpacked
        unzip -q $src -d unpacked
        runHook postUnpack
      '';
      sourceRoot = "unpacked";
      installPhase = ''
        runHook preInstall
        mkdir -p $out/Applications
        app=$(find . -maxdepth 3 -name '*.app' -type d | head -n1)
        cp -R "$app" "$out/Applications/"
        runHook postInstall
      '';
      meta.platforms = pkgs.lib.platforms.darwin;
    };
  in {
    home.packages = lib.optionals pkgs.stdenv.isDarwin [ledgera];
  };
}
