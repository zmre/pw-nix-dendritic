{inputs, ...}: let
  username = "zmre";
  hostname = "volantis";

  # Helper: filter a list of module names to only those that exist in moduleSet
  filterModules = moduleSet: names:
    builtins.filter (m: m != null) (
      map (n: moduleSet.${n} or null) names
    );

  # Single source of truth: all desired modules by name
  wantedModules = [
    # System-only
    "browsers-gui"
    "comms-gui"
    "gui"
    "media-gui"
    "ssh"
    "system"
    "tailscale"
    "volantis-configuration"
    "virtualization"

    # Cross-platform or home-manager only
    "ai"
    "dev"
    "filemanagement"
    "filemanagement-gui"
    "hacking"
    "media"
    "network"
    "security"
    "security-extra"
    "shell"
    "vim"
    "window-mgmt"
  ];

  nixosMods = filterModules inputs.self.nixosModules wantedModules;
  homeMods = filterModules inputs.self.modules.homeManager wantedModules;
in {
  flake-file.inputs.nixos-hardware.url = "github:NixOS/nixos-hardware";

  flake.nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [inputs.nixos-hardware.nixosModules.framework-11th-gen-intel] ++ nixosMods;
  };

  flake.nixosModules.volantis-configuration = {pkgs, ...}: {
    config = {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${username} = {
        imports = homeMods;
        home.username = username;
        home.homeDirectory = "/home/${username}";
        home.stateVersion = "25.05";
      };
      users.defaultUserShell = pkgs.zsh;
      users.users.${username} = {
        home = "/home/${username}";
        shell = pkgs.stable.zsh;
        packages = with pkgs; [
          tree # this is just a test, really
        ];
        isNormalUser = true;
        extraGroups = ["wheel" "power" "docker" "ollama" "render" "video" "nginx" "networkmanager" "libvirtd" "ubertooth" "plugdev" "wireshark"];
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDXh/Nzg2PjtiaOmAAOrEiWrEOjmi6Ps5Jtvu1WqrWtXQYP7g6K0Unx8JGt5GWjeLO6lblDs7nvly3kw3bHDsbXCqYFLqLO0PTKXIaX8spiJ/+r0Pd70Nq5ZNOgoL87hKTXQwwn4FvVzBAu51KS05ZXdfT5xBkzZJc2bcEjR2uIaSI7R27hAyfVMbUx52+sUyi3uShMGmOnrHJbTzNPLjFBXBjNTZTIVI0ztUAGmeiee/ON0yVeONGTldfUXiCM7KcUWVSvlnE3agI/O2p/854bdfIt2KxKRgzBYwVInVc5k8RVlGzCfzw1qdx4nQiky6d2hAek2K9FxG5SnfIDUHUZ test cert 1"
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHyqQGP6vlWB9xV61sF9vJubmHMfKwLeTsweia2pdDRJayTp0xGFMa1uTgvfacmqOqcwL8w9cia4PmTOskVf1EQ= pwalsh@attolia"
        ];
      };
      nixpkgs.config.allowUnfree = true;
      boot = {
        loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };
        supportedFilesystems = ["btrfs"];
        kernelPackages = pkgs.linuxPackages_latest;
        initrd.checkJournalingFS = false;
        initrd.availableKernelModules = ["xhci_pci" "thunderbolt" "nvme" "usb_storage" "uas" "sd_mod"];
        initrd.kernelModules = ["i915"];
        kernelModules = ["kvm-intel"];
        extraModulePackages = [];
        kernelParams = ["mem_sleep_default=deep" "nvme.noacpi=1" "net.ifnames=1"];
        tmp.cleanOnBoot = true;
        tmp.useTmpfs = true;
      };

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/4430cd85-50db-467e-a58f-14f6255847da";
        fsType = "btrfs";
        options = ["subvol=nixos" "compress=zstd" "noatime"];
      };

      boot.initrd.luks.devices."nixenc".device = "/dev/disk/by-uuid/cbfcd419-a732-4720-86f5-5ea80405f304";

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/3029-E285";
        fsType = "vfat";
      };

      swapDevices = [{device = "/dev/disk/by-uuid/5f7d629f-d1a7-485b-8223-c1f13af96ed6";}];

      environment.sessionVariables = {
        GDK_DPI_SCALE = "1.5";
        QT_SCALE_FACTOR = "1.5";
      };

      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
      };

      services.zfs.autoScrub.enable = true;
      services.zfs.autoSnapshot.enable = true;

      nixpkgs.hostPlatform = "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = true;
      hardware.enableAllFirmware = true;
      hardware.hackrf.enable = true;
      hardware.ubertooth.enable = true;
      services.pulseaudio.enable = true;
      # no bluetooth on boot
      hardware.bluetooth.enable = true;
      hardware.bluetooth.powerOnBoot = false;
      security.rtkit.enable = true; # bring in audio
      services.blueman.enable = true;
      # pipewire brings better audio/video handling
      services.pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;
      };
      # Enable touchpad support
      services.libinput = {
        enable = true;
        touchpad = {
          accelSpeed = "0.7";
          naturalScrolling = true;
          middleEmulation = true;
          tapping = true;
          scrollMethod = "twofinger";
          #disableWhileTyping = true;
        };
      };
      services.autorandr.enable = true; # detect displays
      services.fprintd.enable = true; # enable fingerprint scanner
      # Allow fingerprint use by root and zmre
      security.polkit.enable = true;
      security.polkit.extraConfig = ''
        polkit.addRule(function (action, subject) {
          if (action.id == "net.reactivated.fprint.device.enroll") {
            return subject.user == "zmre" || subject.user == "root" ? polkit.Result.YES : polkit.Result.NO
          }
        })
      '';

      security.sudo = {
        enable = true;
        execWheelOnly = true;
        extraConfig = ''
          Defaults   timestamp_timeout=-1
        '';
      };

      # Set your time zone.
      time.timeZone = "America/Denver";

      # Select internationalisation properties.
      i18n.defaultLocale = "en_US.UTF-8";

      console = {
        font = "Lat2-Terminus16";
        # keyMap = "us";
        useXkbConfig = true; # use xkb.options in tty.
      };

      # Configure keymap in X11
      services.xserver.xkb.layout = "us";
      services.xserver.xkb.options = "caps:escape";

      # Enable CUPS to print documents.
      services.printing.enable = true;

      # Update framework firmware as needed
      services.fwupd = {
        enable = true;
        extraRemotes = ["lvfs-testing"];
        # Might be necessary once to make the update succeed
        uefiCapsuleSettings.DisableCapsuleUpdateOnDisk = true;
      };

      # It was trying to upgrade on wake from sleep and sometimes failed in the background
      # because the wifi wasn't up yet, then left my system in a weird state without a
      # current per-user profile in place. So for now, I'll upgrade deliberately.
      # Also, I'm using flakes now, so different system
      system.autoUpgrade.enable = false;

      powerManagement.enable = true;

      # List packages installed in system profile.
      # You can use https://search.nixos.org/ to find more packages (and options).
      environment.systemPackages = with pkgs; [
        firmware-manager
        apfsprogs
        libsecret
        psmisc
        veracrypt
        libva-utils
        compsize # btrfs util
        x11_ssh_askpass
        veracrypt
      ];

      services.locate.enable = true;
      services.timesyncd.enable = true;
      services.earlyoom.enable = true;
      programs.ssh.startAgent = true;
      programs.dconf.enable = true;
      programs.light.enable = true;
      # clight requires a latitude and longitude
      location.latitude = 38.0;
      location.longitude = -105.0;
      programs.mtr.enable = true;
      services.udisks2 = {
        enable = true;
        mountOnMedia = true;
        settings = {
          "mount_options.conf" = {
            defaults = {
              defaults = "noatime";
            };
          };
        };
      };

      networking = {
        hostId = "f0e93d87";
        hostName = hostname;
        firewall = {
          enable = true;
          allowPing = false;
          checkReversePath = false;
        };
        wireless.interfaces = ["wlan0"];
        wireless.iwd.enable = true;
        networkmanager = {
          enable = false;
          wifi.backend = "iwd";
          # getting error: ‘network-manager-applet-1.24.0’, is not a NetworkManager plug-in. Those need to have a ‘networkManagerPlugin’ attribute.
          # just commenting for now 2022-05-30
          #packages = with pkgs.stable; [ networkmanagerapplet ];
          # don't use dhcp dns... use settings below instead
          dns = "none";
        };
        # The global useDHCP flag is deprecated, set to false here.
        useDHCP = false;
        interfaces.wlan0.useDHCP = true;

        # no longer using local dns -- tailscale settings will take
        # over automatically and make sure all dns is safe
        nameservers = ["1.1.1.1" "8.8.8.8"];
        resolvconf.useLocalResolver = false;

        stevenblack.enable = true; # hosts based blocklist
      };

      # This option defines the first version of NixOS you have installed on this particular machine,
      # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
      #
      # Most users should NEVER change this value after the initial install, for any reason,
      # even if you've upgraded your system to a new NixOS release.
      #
      # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
      # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
      # to actually do that.
      #
      # This value being lower than the current NixOS release does NOT mean your system is
      # out of date, out of support, or vulnerable.
      #
      # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
      # and migrated your data accordingly.
      #
      # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
      system.stateVersion = "25.05"; # Did you read the comment?
    };
  };
}
