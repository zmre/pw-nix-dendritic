{
  config,
  inputs,
  ...
}: let
  common = {pkgs, ...}: {
    time.timeZone = "America/Denver";

    documentation.enable = true;
    documentation.info.enable = true;
    documentation.man.enable = true;

    # environment setup
    environment = {
      ${
        if pkgs.stdenv.isLinux
        then "sessionVariables"
        else "variables"
      } = {
        LANGUAGE = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
      };
      systemPackages = with pkgs; [
        binutils
        cachix
        coreutils
        curl
        dig
        dnsutils
        git
        gnugrep
        gnused
        lsof
        net-tools
        pciutils
        usbutils
        vim
        wget
      ];

      # etc = {
      #   home-manager.source = "${inputs.home-manager}";
      #   nixpkgs-unstable.source = "${inputs.nixpkgs}";
      #   nixpkgs-stable.source =
      #     if pkgs.stdenvNoCC.isDarwin
      #     then "${inputs.nixpkgs-stable-darwin}"
      #     else "${inputs.nixpkgs-stable}";
      # };

      # list of acceptable shells in /etc/shells
      shells = with pkgs; [bash zsh];
      pathsToLink = ["/libexec" "/share/zsh"];
    };
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      enableBashCompletion = true;
    };
  };
in {
  flake.darwinModules.system = {
    imports = [
      common
      inputs.home-manager.darwinModules.home-manager
    ];
  };

  flake.nixosModules.system = {
    imports = [
      common
      inputs.home-manager.nixosModules.default
    ];
  };
}
