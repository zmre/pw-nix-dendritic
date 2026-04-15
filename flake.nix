# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  description = "My updated nix config; now more 'dendritic'";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  nixConfig = {
    download-buffer-size = 1073741824;
    extra-experimental-features = "nix-command flakes pipe-operators";
    extra-substituters = [
      "https://cache.nixos.org?priority=1"
      "https://zmre.cachix.org?priority=2"
      "https://nix-community.cachix.org?priority=3"
      "https://numtide.cachix.org?priority=4"
      "https://yazi.cachix.org?priority=5"
      "https://ghostty.cachix.org?priority=6"
      "https://cache.nixos-cuda.org?priority=7"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "zmre.cachix.org-1:WIE1U2a16UyaUVr+Wind0JM6pEXBe43PQezdPKoDWLE="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
    nar-buffer-size = 134217728;
  };

  inputs = {
    city-explorer = {
      url = "github:zmre/city-explorer";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat.url = "github:NixOS/flake-compat";
    flake-file.url = "github:vic/flake-file";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    gh-feed = {
      url = "github:rsteube/gh-feed";
      flake = false;
    };
    gh-worktree = {
      url = "github:zmre/gh-worktree";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hackernews-tui = {
      url = "github:aome510/hackernews-TUI?ref=v0.13.5";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-freetube = {
      url = "github:pikachuexe/homebrew-freetube";
      flake = false;
    };
    import-tree.url = "github:vic/import-tree";
    iris = {
      url = "git+ssh://git@github.com/zmre/iris.git";
      inputs.flake-parts.follows = "flake-parts";
    };
    ironhide = {
      url = "github:IronCoreLabs/ironhide";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
      };
    };
    ironoxide = {
      url = "github:IronCoreLabs/ironoxide-cli";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
      };
    };
    mbr-markdown-browser.url = "github:zmre/mbr-markdown-browser";
    mdterm = {
      url = "github:bahdotsh/mdterm";
      flake = false;
    };
    nix-auth.url = "github:numtide/nix-auth";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-stable-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";
    nur = {
      url = "github:nix-community/NUR";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
    };
    pwaerospace = {
      url = "github:zmre/aerospace-sketchybar-nix-lua-config";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    pwneovide.url = "github:zmre/pwneovide";
    pwnvim.url = "github:zmre/pwnvim";
    rust-overlay.url = "github:oxalica/rust-overlay";
    sbhosts = {
      url = "github:StevenBlack/hosts";
      flake = false;
    };
    yazi-flavors = {
      url = "github:yazi-rs/flavors";
      flake = false;
    };
    yazi-quicklook = {
      url = "github:vvatikiotis/quicklook.yazi";
      flake = false;
    };
  };
}
