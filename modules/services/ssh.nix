{
  flake.nixosModules.ssh = {pkgs, ...}: {
    # Enable the OpenSSH daemon.
    services.openssh = {
      enable = true;
      allowSFTP = true;
      openFirewall = true;
      settings = {
        # Allow public key authentication
        PubkeyAuthentication = true;
        # Disable password auth for security (optional but recommended)
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        AllowUsers = ["pwalsh"];
        Subsystem = "sftp internal-sftp ${pkgs.openssh}/libexec/sftp-server";
      };
    };
    programs.mosh.enable = false;
    programs.mosh.openFirewall = false;
  };
}
