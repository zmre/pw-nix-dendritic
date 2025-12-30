{
  flake.darwinModules.virtualization = {pkgs, ...}: {
    environment.systemPackages = [pkgs.container]; # macos native vm
    #homebrew.casks = ["container"]; # macos native vm
  };

  flake.nixosModules.virtualization = {pkgs, ...}: {
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
      autoPrune.dates = "weekly";
      # Don't start on boot; but it will start on-demand
      enableOnBoot = true;
    };

    virtualisation.libvirtd = {
      enable = true;
      onBoot = "start";
      qemu.package = pkgs.qemu_kvm;
    };
  };

  flake.modules.homeManager.virtualization = {pkgs, ...}: {
    home.packages = with pkgs; [
      colima
      docker
    ];
  };
}
