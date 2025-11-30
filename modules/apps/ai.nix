{inputs, ...}: {
  flake-file.inputs.pwai.url = "git+ssh://git@github.com/zmre/pwai.git";

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
    ];
    programs = {
    };
  };
}
