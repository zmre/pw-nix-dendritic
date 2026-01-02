# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  description = "My updated nix config now more 'dendritic'";

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
    darwin = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-darwin/nix-darwin";
    };
    disko = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/disko";
    };
    flake-compat.url = "github:NixOS/flake-compat";
    flake-file.url = "github:vic/flake-file";
    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
      url = "github:hercules-ci/flake-parts";
    };
    flake-utils.url = "github:numtide/flake-utils";
    gh-feed = {
      flake = false;
      url = "github:rsteube/gh-feed";
    };
    gh-worktree = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:zmre/gh-worktree";
    };
    hackernews-tui = {
      flake = false;
      url = "github:aome510/hackernews-TUI";
    };
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager";
    };
    homebrew-cask = {
      flake = false;
      url = "github:homebrew/homebrew-cask";
    };
    homebrew-core = {
      flake = false;
      url = "github:homebrew/homebrew-core";
    };
    homebrew-freetube = {
      flake = false;
      url = "github:pikachuexe/homebrew-freetube";
    };
    import-tree.url = "github:vic/import-tree";
    iris = {
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
      url = "git+ssh://git@github.com/zmre/iris.git";
    };
    ironhide = {
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
      };
      url = "github:IronCoreLabs/ironhide";
    };
    ironoxide = {
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
      };
      url = "github:IronCoreLabs/ironoxide-cli";
    };
    mbr-markdown-browser.url = "github:zmre/mbr-markdown-browser";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-index-database = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/nix-index-database";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-lib.follows = "nixpkgs";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-stable-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";
    nur = {
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:nix-community/NUR";
    };
    pwaerospace = {
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:zmre/aerospace-sketchybar-nix-lua-config";
    };
    pwneovide = {
      inputs = {
        flake-compat.follows = "flake-compat";
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        pwnvim.follows = "pwnvim";
      };
      url = "github:zmre/pwneovide";
    };
    pwnvim = {
      inputs = {
        flake-compat.follows = "flake-compat";
        flake-utils.follows = "flake-utils";
      };
      url = "github:zmre/pwnvim";
    };
    rust-overlay.url = "github:oxalica/rust-overlay";
    sbhosts = {
      flake = false;
      url = "github:StevenBlack/hosts";
    };
    systems.url = "github:nix-systems/default";
    yazi-flavors = {
      flake = false;
      url = "github:yazi-rs/flavors";
    };
    yazi-quicklook = {
      flake = false;
      url = "github:vvatikiotis/quicklook.yazi";
    };
  };

}
