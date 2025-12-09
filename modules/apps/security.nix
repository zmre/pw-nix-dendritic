{inputs, ...}: {
  flake-file.inputs.sbhosts.url = "github:StevenBlack/hosts";

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
      "chkrootkit" # TODO: moved here 2024-03-25 since nix version is broken
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
  flake.darwinModules.security = {pkgs, ...}: {
    environment.etc.hosts.source = "${inputs.sbhosts}/hosts";
  };

  flake.modules.homeManager.security = {
    pkgs,
    lib,
    ...
  }: {
    home.packages = with pkgs; [
      exploitdb
      # Recon
      arp-scan
      arping
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
}
