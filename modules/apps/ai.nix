{inputs, ...}: {
  flake-file.inputs.iris.url = "git+ssh://git@github.com/zmre/iris.git";
  # Note: Do NOT follow nixpkgs - iris needs its own nixpkgs version for
  # fetchNpmDepsWithPackuments compatibility with gemini-cli
  flake-file.inputs.iris.inputs.flake-parts.follows = "flake-parts";

  # Personal layer over IronCore's tachikoma: its own omp profile, a
  # path-scoped approval gate, and personal skills, agents and rules. Private
  # repo, so eval and build need GitHub auth (nix `access-tokens`).
  #
  # Safe to follow nixpkgs: eva's own derivations are shell wrappers and file
  # merges, and tachikoma's omp is a fetchurl of an upstream release asset.
  # eva's llm-agents input, which is the one with cache-sensitive bun2nix
  # builds, declines to follow on its own side.
  flake-file.inputs.eva.url = "git+ssh://git@github.com/zmre/eva.git";
  flake-file.inputs.eva.inputs.nixpkgs.follows = "nixpkgs";

  # flake-file.inputs.alita.url = "git+ssh://git@github.com/ironcorelabs/alita.git";
  # flake-file.inputs.alita.inputs.nixpkgs.follows = "nixpkgs";
  # flake-file.inputs.alita.inputs.flake-parts.follows = "flake-parts";

  flake.darwinModules.ai-gui = {
    homebrew.casks = [
      #"chatgpt" # freaking openai is trying to worm its way into every part of my system. i'm constantly denying it access. browser only going forward.
      "claude"
      "macwhisper"
      "ollama-app"
      "lm-studio"
    ];
    homebrew.brews = [
      "jundot/omlx/omlx"
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
  in {
    imports =
      (with inputs.self.modules.homeManager; [
        herdr
      ])
      ++ [inputs.eva.homeManagerModules.eva];

    # Installs `eva`, `tachikoma` and `pi`. The deny list is deliberately not
    # set here: this repo is public, and naming a directory you want kept away
    # from an agent defeats the purpose. It belongs in eva's own default for
    # `programs.eva.policy.deny`.
    programs.eva.enable = true;

    home.packages = with pkgs; [
      #aichat-wrapped # ai cli tool that can use local rag, local models, etc.
      irisPkg # my personal assistant, which wraps other tools and has crap tons of configs
      #inputs.alita.packages.${system}.default # ironcore version -- just for demo and testing purposes
      stable.whisper-cpp # Allow GPU accelerated local transcriptions
      python313Packages.huggingface-hub
      python313Packages.hf-transfer
      # herdr is installed by programs.herdr — see apps/herdr.nix
      tuicr # terminal review diff where you can add comments and then share in different ways
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
