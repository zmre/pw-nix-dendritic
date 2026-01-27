{
  flake.nixosModules.nfs = {pkgs, ...}: let
    nfsShares = ["web" "video" "homes" "Audiobook" "Books" "Podcasts"];
  in {
    environment.systemPackages = with pkgs; [
      nfs-utils
    ];
    services.rpcbind.enable = true;

    fileSystems = builtins.listToAttrs (map (share: {
        name = "/mnt/${share}";
        value = {
          # synology1, but let's save the dns to make things maybe slightly faster
          device = "192.168.37.11:/volume1/${share}";
          fsType = "nfs";
          options = [
            "nfsvers=4.1" # NFS version
            "x-systemd.automount" # Auto-mount on access
            "noauto" # Don't mount at boot (combine with automount)
            #"x-systemd.idle-timeout=600"  # Unmount after 10 min idle
          ];
        };
      })
      nfsShares);
  };
}
