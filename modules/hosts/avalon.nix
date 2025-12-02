{
  self,
  inputs,
  lib,
  pkgs,
  config,
  ...
}: {
  flake-file.inputs.nixos-hardware.url = "github:NixOS/nixos-hardware";
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.nixpkgs = {
    url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  flake.nixosConfigurations.avalon = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.nixosModules; [
      inputs.disko.nixosModules.disko
      inputs.nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
      amd-gpu
      avalon-configuration
      avalon-disk
      nix-settings
      users
      home-manager
      nfs
      ssh
      #gui
      tailscale
      packages
      ai
      nginx-rtmp
      plex
    ];
  };

  flake.homeConfigurations.avalon = inputs.home-manager.lib.homeManagerConfiguration {
    modules = with config.flake.modules.homeManager; [
      shell
      {
        home.username = "pwalsh";
        home.homeDirectory = "/home/pwalsh";
        home.stateVersion = "25.05";
      }
    ];
  };

  flake-file.description = "Avalon's dendritic setup.";

  flake.nixosModules.avalon-configuration = {
    config,
    lib,
    pkgs,
    ...
  }: {
    # modules = [
    # Reference other modules from flake config
    # ../nixos/users.nix
    # ../nixos/networking.nix
    # ../nixos/packages.nix
    # ../hardware/disk-config.nix
    #   inputs.disko.nixosModules.disko
    #   inputs.nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
    #   inputs.determinate.nixosModules.default
    # ];
    config = {
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
        initrd.availableKernelModules = ["nvme" "xhci_pci" "thunderbolt" "usb_storage" "usbhid" "sd_mod"];
        tmp.cleanOnBoot = true;
        tmp.useTmpfs = true;
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
      networking.hostName = "avalon"; # Define your hostname.

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
      # environment.systemPackages = with pkgs; [
      #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      #   wget
      # ];

      # programs.gnupg.agent = {
      #   enable = true;
      #   enableSSHSupport = true;
      # };

      # List services that you want to enable:

      # Open ports in the firewall.
      # networking.firewall.allowedUDPPorts = [ ... ];
      # Or disable the firewall altogether.
      networking.firewall.enable = false;
      #networking.firewall.checkReversePath = false;

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
