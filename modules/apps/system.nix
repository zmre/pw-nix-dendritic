{
  # The file system/common.nix imports all of the flakeModules.common into
  # nixos and darwin
  flake.flakeModules.common = {pkgs, ...}: {
    environment.systemPackages = with pkgs.stable; [
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
  };
}
