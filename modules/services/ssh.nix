{
  flake.nixosModules.ssh = {pkgs, ...}: {
    # Enable the OpenSSH daemon.
    services.openssh.enable = true;
    services.openssh.allowSFTP = false;
    services.openssh.openFirewall = true;
    programs.mosh.enable = true;
    programs.mosh.openFirewall = true;
  };
}
