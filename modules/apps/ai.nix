{inputs, ...}: {
  flake-file.inputs.iris.url = "git+ssh://git@github.com/zmre/iris.git";
  # Note: Do NOT follow nixpkgs - iris needs its own nixpkgs version for
  # fetchNpmDepsWithPackuments compatibility with gemini-cli
  flake-file.inputs.iris.inputs.flake-parts.follows = "flake-parts";

  # flake-file.inputs.alita.url = "git+ssh://git@github.com/ironcorelabs/alita.git";
  # flake-file.inputs.alita.inputs.nixpkgs.follows = "nixpkgs";
  # flake-file.inputs.alita.inputs.flake-parts.follows = "flake-parts";

  flake.darwinModules.ai-gui = {
    homebrew.casks = [
      "chatgpt"
      "claude"
      "macwhisper"
      "ollama-app"
      "lm-studio"
    ];
  };

  flake.nixosModules.ai-gui = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      #chatgpt
    ];
  };

  flake.modules.homeManager.ai = {
    pkgs,
    lib,
    ...
  }: let
    inherit (pkgs.stdenvNoCC.hostPlatform) system;
    irisPkg = inputs.iris.packages.${system}.default;
    aichat-wrapped = let
      pkg = pkgs.aichat;
      tools = with pkgs; [argc jq poppler-utils pdfminer tesseract];
      toolPath = pkgs.lib.makeBinPath tools;
    in
      pkgs.runCommand "${pkg.pname}-wrapped" {
        nativeBuildInputs = [pkgs.makeBinaryWrapper];
      } ''
        mkdir -p $out/bin
        makeBinaryWrapper ${pkgs.lib.getExe pkg} $out/bin/${pkg.pname} --prefix PATH : ${toolPath}
      '';
  in {
    home.packages = with pkgs; [
      aichat-wrapped # ai cli tool that can use local rag, local models, etc.
      irisPkg # my personal assistant, which wraps other tools and has crap tons of configs
      #inputs.alita.packages.${system}.default # ironcore version -- just for demo and testing purposes
      stable.whisper-cpp # Allow GPU accelerated local transcriptions
      python313Packages.huggingface-hub
      python313Packages.hf-transfer
    ];

    # Link opencode's skills/agents at iris's bundled copies. These are
    # symlinks into the iris store path, so they re-point on every activation
    # (and whenever iris updates to a new store path).
    xdg.configFile = {
      "opencode/skills".source = "${irisPkg}/claude/skills";
      "opencode/agents".source = "${irisPkg}/claude/agents";
    };

    programs = {
    };
  };
}
