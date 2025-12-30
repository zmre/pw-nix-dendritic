{inputs, ...}: {
  flake-file.inputs.sbhosts.url = "github:StevenBlack/hosts";
  flake-file.inputs.sbhosts.flake = false; # this is a lie, but we don't want to import its dependencies

  flake.darwinModules.security-gui = {
    homebrew.casks = [
      "blockblock"
      "burp-suite" # TODO: move to home-manager? (burpsuite)
      "gpg-suite"
      "knockknock"
      "little-snitch"
      #"lockrattler"
      #"metasploit" # TODO 2024-07-31 nix version not running on mac; 2025-12-09 brew version deprecated
      "qflipper"
      "reikey"
      "silentknight"
      "wireshark-chmodbpf"
      #"yubico-yubikey-manager" # deprecated
      #"yubico-authenticator" # using app store version
      "zap" # TODO: move to home-manager? (zap)
    ];
    homebrew.brews = [
      "recon-ng" # TODO nix version doesn't work on mac at last try 2024-07-31
      "hashcat" # the nix one only builds on linux
      "hydra" # the nix one only builds on linux
      "p0f" # the nix one only builds on linux
    ];
    homebrew.masApps = {
      "1Blocker" = 1365531024;
      "Apple Configurator" = 1037126344;
      "Disk Decipher" = 516538625;
      "MailTrackerBlocker" = 6450760473; # Mail extension for blocking tracker pixels
      "Strongbox" = 1270075435; # password manager
      "Vinegar" = 1591303229;
      "Wipr" = 1662217862;
      "Yubico Authenticator" = 1497506650;
    };
  };

  flake.nixosModules.security-gui = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      keepassxc
    ];
    services.gpg-agent = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      pinentryPackage = pkgs.pinentry-tty;
    };
  };

  flake.darwinModules.security = {pkgs, ...}: {
    environment.etc.hosts.source = "${inputs.sbhosts}/hosts";
  };

  flake.modules.homeManager.security = {pkgs, ...}: {
    home.packages = with pkgs; [
      exploitdb
      # Recon
      arp-scan
      pkgs.stable.arping
      dnsenum
      fierce # dns recon
      hping
      nikto
      nmap # -graphical
      rustscan
      ngrep
      dnstop
      dirb
      gobuster
      urlhunter
      netcat
      vulnix # check for live nix apps that are listed in NVD
      yubikey-manager # cli for yubikey
    ];
    programs = {
    };
  };

  flake.modules.homeManager.security-extra = {
    pkgs,
    lib,
    ...
  }: {
    home.packages = with pkgs;
      [
        # Exploitation
        exploitdb
        sqlmap
        arpoison

        # Recon
        avahi
        arp-scan
        dnsenum
        dnsrecon
        fierce # dns recon
        httrack # offline browser / website mirror
        fping
        boofuzz
        hping
        masscan
        nikto
        onesixtyone
        nmap # -graphical
        rustscan
        snmpcheck
        sslscan
        #theharvester # temp disable; broken 2024-09-06
        socialscan
        urlhunter
        cloudbrute
        #sn0int # temp disable cuz rust build issue 2024-08-26
        sslsplit
        # wireshark moved to nixos config
        # pick one of wireshark or wireshark-cli
        pkgs.stable.wireshark
        #wireshark-cli

        # Passwords
        fcrackzip
        john
        hashcat-utils
        pdfcrack
        rarcrack
        crunch # wordlist generator
        #chntpw
        #crowbar # build issues on 2024-10-30

        # Sniffing
        ettercap
        #bettercap # build issues on 2024-10-30
        proxify
        wireshark
        ngrep
        dnstop
        nload
        #netsniff-ng ?

        # Web
        dirb
        gobuster
        #wfuzz
        urlhunter

        # Crypto / stego
        #exif # installed elsewhere
        zsteg

        # Manipulation
        gdb
        radare2
        sqlitebrowser
        unrar
        netcat
        pwncat # netcat on steroids
        capstone # cstool disassembly tool
        binwalk

        # misc
        faraday-cli
        corkscrew # tunnel ssh through http proxies
        pwntools
      ]
      ++ lib.optionals
      (!pkgs.stdenv.isDarwin) [
        # Things that only build on Linux go here
        # Exploitation
        metasploit

        # Recon
        recon-ng
        enum4linux-ng # local privesc finder
        ike-scan
        pktgen
        ostinato
        #zmap # currently marked broken 2022-01-31

        # Passwords
        hashcat
        thc-hydra
        hcxtools
        ncrack # network auth cracker
        brutespray

        # Sniffing
        dsniff
        tcpflow
        p0f
        netsniff-ng
        mitmproxy
        dhcpdump
        proxychains

        # Web
        burpsuite
        zap
        wpscan

        # Wifi
        kismet
        wifite2
        reaverwps
        aircrack-ng

        # Bluetooth
        bluez
        # rfid
        proxmark3
        gnuradio
        gqrx
        hackrf
        ubertooth
        multimon-ng

        # Crypto / stego
        pngcheck
        stegseek

        # Manipulation
        #radare2-cutter
        #afl # fuzzer tool
        # cloud
        cloud-nuke
        cloudfox
        ec2stepshell
        gato
        gcp-scanner
        #ggshield
        goblob
        imdshift
        pacu
        poutine
        #prowler
        yatas
        # git
        bomber-go
        cargo-audit
        credential-detector
        deepsecrets
        detect-secrets
        freeze
        git-secret
        gitjacker
        gitleaks
        gitls
        gokart
        legitify
        secretscanner
        skjold
        tell-me-your-secrets
        trufflehog
        whispers
        xeol

        # Misc
        keedump
        sploitscan
      ];
  };
}
