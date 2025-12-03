{
  flake.nixosModules.ssh = {pkgs, ...}: {
    # Enable the OpenSSH daemon.
    services.openssh = {
      enable = true;
      allowSFTP = false;
      openFirewall = true;
      settings = {
        # Allow public key authentication
        PubkeyAuthentication = true;
        # Disable password auth for security (optional but recommended)
        PasswordAuthentication = false;
      };
    };
    programs.mosh.enable = false;
    programs.mosh.openFirewall = true;
  };
}
