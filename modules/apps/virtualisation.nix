{
  flake.darwinModules.virtualization = {pkgs, ...}: {
    environment.systemPackages = [pkgs.container]; # macos native vm
    #homebrew.casks = ["container"]; # macos native vm
  };

  flake.nixosModules.virtualization = {pkgs, ...}: {
    virtualisation.docker = {
      enable = false;
      autoPrune.enable = true;
      autoPrune.dates = "weekly";
      # Don't start on boot; but it will start on-demand
      enableOnBoot = true;
    };

    virtualisation.oci-containers.backend = "podman"; # or docker
    virtualisation.podman = {
      enable = pkgs.stdenv.isLinux;
      autoPrune.enable = true;
      dockerCompat = true;
    };
    virtualisation.libvirtd = {
      enable = true;
      onBoot = "start";
      qemu.package = pkgs.qemu_kvm;
    };
  };

  flake.modules.homeManager.virtualization = {
    pkgs,
    lib,
    ...
  }: {
    home.packages = with pkgs;
      [
        colima
        #docker
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        podman
        toolbox
      ];
  };
}
