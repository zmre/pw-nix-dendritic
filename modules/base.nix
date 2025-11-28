{inputs, ...}: {
  flake-file.description = "My updated nix config now more 'dendritic'";
  flake-file.inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  flake-file.inputs.nixpkgs-stable.url = "github:nixos/nixpkgs/release-25.05";
  flake-file.inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  flake-file.inputs.flake-file.url = "github:vic/flake-file";
  flake-file.inputs.import-tree.url = "github:vic/import-tree";

  imports = [
    inputs.flake-file.flakeModules.dendritic
    inputs.flake-file.flakeModules.allfollow # not sure I like this all the time
  ];

  systems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-darwin"
    "x86_64-linux"
  ];

  flake-file.nixConfig = {
    allowUnfree = true;
    extra-experimental-features = "nix-command flakes pipe-operators";
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://zmre.cachix.org"
      "https://yazi.cachix.org"
      "https://ghostty.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "zmre.cachix.org-1:WIE1U2a16UyaUVr+Wind0JM6pEXBe43PQezdPKoDWLE="
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
    ];
  };

  perSystem = {
    self,
    system,
    inputs,
    ...
  }: {
    _module.args = {
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
        config.allowUnfree = true;
      };

      pkgsStable = import inputs.nixpkgs-stable {
        inherit system;
        overlays = [self.overlays.default];
        config.allowUnfree = true;
      };
    };
  };
}
