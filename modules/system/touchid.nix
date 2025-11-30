{
  flake.darwinModules.touchid = {pkgs, ...}: {
    # environment.systemPackages = with pkgs; [pam-reattach];
    security.pam.services.sudo_local = {
      enable = true;
      reattach = true;
      touchIdAuth = true;
    };
  };
}
