_: let
  common = {
    nix.settings.allowed-users = ["@users" "@staff"];
  };
in {
  # Using system module to auto-add everywhere
  flake.darwinModules.system = {
    imports = [
      common
    ];
    networking = {
      applicationFirewall = {
        enable = true;
        enableStealthMode = true;
      };
    };
    system.defaults = {
      #
      # `man configuration.nix` on mac is useful in seeing available options
      # `defaults read -g` on mac is useful to see current settings
      LaunchServices = {
        # quarantine downloads until approved
        LSQuarantine = true;
      };
      # login window settings
      loginwindow = {
        # disable guest account
        GuestEnabled = false;
        # show name instead of username
        SHOWFULLNAME = false;
        # Disables the ability for a user to access the console by typing “>console” for a username at the login window.
        DisableConsoleAccess = true;
      };
      CustomUserPreferences = {
        "com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = true;
          # Check for software updates daily, not just once per week
          # Except it doesn't seem to be doing this. And in some guides, it shows referencing a prefs file
          # Going to cover my bases and add this a second time in a second place directly in the activation script
          ScheduleFrequency = 1;
          # Download newly available updates in background
          AutomaticDownload = 1;
          # Install System data files & security updates
          CriticalUpdateInstall = 1;
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        # Turn on app auto-update
        "com.apple.commerce".AutoUpdate = true;
      };
    };
  };

  flake.nixosModules.system = {
    imports = [
      common
    ];
    security.lockKernelModules = true;
    security.forcePageTableIsolation = true;
    security.protectKernelImage = true;
    boot.kernelParams = [
      # Don't merge slabs
      "slab_nomerge"

      # Overwrite free'd pages
      "page_poison=1"

      # Enable page allocator randomization
      "page_alloc.shuffle=1"

      # Disable debugfs
      "debugfs=off"
    ];
    boot.blacklistedKernelModules = [
      # Obscure network protocols
      "ax25"
      "netrom"
      "rose"

      # Old or rare or insufficiently audited filesystems
      "adfs"
      "affs"
      "bfs"
      "befs"
      "cramfs"
      "efs"
      "erofs"
      "exofs"
      "freevxfs"
      "f2fs"
      "hfs"
      "hpfs"
      "jfs"
      "minix"
      "nilfs2"
      "ntfs"
      "omfs"
      "qnx4"
      "qnx6"
      "sysv"
      "ufs"
    ];
    boot.kernel.sysctl."net.ipv4.conf.all.log_martians" = true;
    boot.kernel.sysctl."net.ipv4.conf.all.rp_filter" = "1";
    boot.kernel.sysctl."net.ipv4.conf.default.log_martians" = true;
    boot.kernel.sysctl."net.ipv4.conf.default.rp_filter" = "1";

    # Ignore broadcast ICMP (mitigate SMURF)
    boot.kernel.sysctl."net.ipv4.icmp_echo_ignore_broadcasts" = true;

    # Ignore incoming ICMP redirects (note: default is needed to ensure that the
    # setting is applied to interfaces added after the sysctls are set)
    boot.kernel.sysctl."net.ipv4.conf.all.accept_redirects" = false;
    boot.kernel.sysctl."net.ipv4.conf.all.secure_redirects" = false;
    boot.kernel.sysctl."net.ipv4.conf.default.accept_redirects" = false;
    boot.kernel.sysctl."net.ipv4.conf.default.secure_redirects" = false;
    boot.kernel.sysctl."net.ipv6.conf.all.accept_redirects" = false;
    boot.kernel.sysctl."net.ipv6.conf.default.accept_redirects" = false;

    # Ignore outgoing ICMP redirects (this is ipv4 only)
    boot.kernel.sysctl."net.ipv4.conf.all.send_redirects" = false;
    boot.kernel.sysctl."net.ipv4.conf.default.send_redirects" = false;
  };
}
