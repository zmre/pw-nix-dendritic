{
  self,
  inputs,
  lib,
  pkgs,
  config,
  ...
}: let
  username = "pwalsh";
  hostname = "avalon";

  # Helper: filter a list of module names to only those that exist in moduleSet
  filterModules = moduleSet: names:
    builtins.filter (m: m != null) (
      map (n: moduleSet.${n} or null) names
    );

  # Single source of truth: all desired modules by name
  wantedModules = [
    # System-only
    "amd-gpu"
    "avalon-configuration"
    "avalon-disk"
    "hardened"
    "nfs"
    "nginx-rtmp"
    "ollama"
    "plex"
    "protonmail-bridge"
    "search"
    "ssh"
    "system"
    "tailscale"

    # Cross-platform or home-manager only
    "ai"
    "dev"
    "filemanagement"
    "media"
    "network"
    "protonmail-bridge"
    "shell"
    "vim"
  ];

  nixosMods = filterModules inputs.self.nixosModules wantedModules;
  homeMods = filterModules inputs.self.modules.homeManager wantedModules;
in {
  flake-file.inputs.nixos-hardware.url = "github:NixOS/nixos-hardware";
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules =
      [
        inputs.disko.nixosModules.disko
        inputs.nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
        {hardware.gpu = "rocm";}
      ]
      ++ nixosMods;
  };

  flake.nixosModules.avalon-configuration = {pkgs, ...}: {
    config = {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${username} = {
        imports = homeMods;
        hardware.gpu = "rocm";
        home.username = username;
        home.homeDirectory = "/home/${username}";
        home.stateVersion = "25.05";
        home.sessionVariables = {
          OLLAMA_HOST = "127.0.0.1:11434";
        };
      };
      users.defaultUserShell = pkgs.zsh;
      users.users.${username} = {
        home = "/home/${username}";
        shell = pkgs.stable.zsh;
        packages = with pkgs; [
          tree # this is just a test, really
        ];
        isNormalUser = true;
        extraGroups = ["wheel" "power" "docker" "ollama" "render" "video" "nginx" "networkmanager" "libvirtd"];
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
        supportedFilesystems = ["zfs"];
        initrd.kernelModules = ["zfs"];
        kernelPackages = pkgs.linuxPackages_6_17;
        kernelModules = ["kvm-amd"];
        zfs.package = pkgs.zfs_unstable;
        initrd.availableKernelModules = ["apfs" "nvme" "xhci_pci" "thunderbolt" "usb_storage" "usbhid" "sd_mod"];
        tmp.cleanOnBoot = true;
        tmp.useTmpfs = true;
        extraModulePackages = [pkgs.linuxKernel.packages.linux_6_17.apfs];
      };

      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
      };

      services.zfs.autoScrub.enable = true;
      services.zfs.autoSnapshot.enable = true;

      networking.useDHCP = false;
      networking.interfaces.enp191s0.ipv4.addresses = [
        {
          address = "192.168.37.10";
          prefixLength = 24;
        }
      ];
      networking.defaultGateway = "192.168.37.1";
      networking.nameservers = ["100.100.100.100" "192.168.37.1"];
      networking.stevenblack.enable = true; # hosts based blocklist
      #networking.resolvconf.enable = false;

      nixpkgs.hostPlatform = "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = true;
      hardware.enableAllFirmware = true;

      security.sudo = {
        enable = true;
        execWheelOnly = true;
        extraConfig = ''
          Defaults   timestamp_timeout=-1
        '';
      };

      # zfs requires a hostid
      networking.hostId = "d6e10bc1";
      networking.hostName = hostname; # Define your hostname.

      # We have wifi, but at present there's no real point in setting it up as this box will be plugged into ethernet
      # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

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
      # services.printing.enable = true;

      # Enable sound.
      # services.pulseaudio.enable = true;
      # OR
      # services.pipewire = {
      #   enable = true;
      #   pulse.enable = true;
      # };

      # Enable touchpad support (enabled default in most desktopManager).
      services.libinput.enable = false;

      # Update framework firmware as needed
      services.fwupd = {
        enable = true;
        extraRemotes = ["lvfs-testing"];
      };

      system.autoUpgrade.enable = false;

      powerManagement.enable = false;

      # List packages installed in system profile.
      # You can use https://search.nixos.org/ to find more packages (and options).
      environment.systemPackages = with pkgs; [
        firmware-manager
        apfsprogs
        libsecret
        psmisc
        veracrypt
      ];

      services.locate.enable = true;
      services.timesyncd.enable = true;
      services.earlyoom.enable = true;
      programs.ssh.startAgent = true;
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

      # programs.gnupg.agent = {
      #   enable = true;
      #   enableSSHSupport = true;
      # };

      # List services that you want to enable:

      # Open ports in the firewall.
      # networking.firewall.allowedUDPPorts = [ ... ];
      # Or disable the firewall altogether.
      networking.firewall.enable = true;
      networking.firewall.allowPing = true;
      networking.firewall.checkReversePath = false;

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
