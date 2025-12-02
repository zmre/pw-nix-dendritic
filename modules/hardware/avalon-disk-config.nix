{inputs, ...}: {
  #flake.modules.hosts.avalon.disko = {
  flake.nixosModules.avalon-disk = {...}: {
    config.disko.devices = {
      disk = {
        primary = {
          type = "disk";
          device = "/dev/nvme0n1";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = ["umask=0077"];
                };
              };
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "zroot";
                };
              };
            };
          };
        };
        secondary = {
          type = "disk";
          device = "/dev/nvme1n1";
          content = {
            type = "gpt";
            partitions = {
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "zroot";
                };
              };
            };
          };
        };
      };
      zpool = {
        zroot = {
          type = "zpool";
          rootFsOptions = {
            mountpoint = "none";
            compression = "zstd";
            acltype = "posixacl";
            xattr = "sa";
            atime = "off";
            # Encryption
            encryption = "aes-256-gcm";
            keyformat = "passphrase";
            keylocation = "prompt";
          };
          options.ashift = "12";
          datasets = {
            "root" = {
              type = "zfs_fs";
              options."com.sun:auto-snapshot" = "false";
              mountpoint = "/";

              postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zroot/root@blank$' || zfs snapshot zroot/root@blank";
            };
            "root/nix" = {
              type = "zfs_fs";
              options.mountpoint = "/nix";
              mountpoint = "/nix";
              options."com.sun:auto-snapshot" = "false";
            };

            # README MORE: https://wiki.archlinux.org/title/ZFS#Swap_volume
            # Already created, but apparently it's bad (on nix?) to swap to zfs
            # "root/swap" = {
            #   type = "zfs_volume";
            #   size = "50M";
            #   content = {
            #     type = "swap";
            #   };
            #   options = {
            #     volblocksize = "4096";
            #     compression = "zle";
            #     logbias = "throughput";
            #     sync = "always";
            #     primarycache = "metadata";
            #     secondarycache = "none";
            #     "com.sun:auto-snapshot" = "false";
            #   };
            # };
            "root/home" = {
              type = "zfs_fs";
              mountpoint = "/home";
              options."com.sun:auto-snapshot" = "true";
            };
          };
        };
      };
    };
  };
}
