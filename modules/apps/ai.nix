{inputs, ...}: {
  flake-file.inputs.pwai.url = "git+ssh://git@github.com/zmre/pwai.git";
  flake-file.inputs.pwai.inputs.nixpkgs.follows = "nixpkgs";
  flake-file.inputs.pwai.inputs.flake-parts.follows = "flake-parts";

  # flake-file.inputs.alita.url = "git+ssh://git@github.com/ironcorelabs/alita.git";
  # flake-file.inputs.alita.inputs.nixpkgs.follows = "nixpkgs";
  # flake-file.inputs.alita.inputs.flake-parts.follows = "flake-parts";

  flake.darwinModules.ai-gui = {
    homebrew.casks = [
      "chatgpt"
      "claude"
      "macwhisper"
      #"ollama-app"
      #"lm-studio"
    ];
  };

  flake.modules.homeManager.ai = {
    pkgs,
    lib,
    ...
  }: let
    system = pkgs.stdenvNoCC.hostPlatform.system;
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
      inputs.pwai.packages.${system}.default # my personal assistant, which wraps other tools and has crap tons of configs
      #inputs.alita.packages.${system}.default # ironcore version -- just for demo and testing purposes
      whisper-cpp # Allow GPU accelerated local transcriptions
    ];
    programs = {
    };
  };
}
