_: let
  substituters = [
    {
      url = "https://cache.nixos.org";
      publicKey = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
      priority = 1;
    }
    {
      url = "https://zmre.cachix.org";
      publicKey = "zmre.cachix.org-1:WIE1U2a16UyaUVr+Wind0JM6pEXBe43PQezdPKoDWLE=";
      priority = 2;
    }
    {
      url = "https://nix-community.cachix.org";
      publicKey = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
      priority = 3;
    }
    {
      url = "https://numtide.cachix.org";
      publicKey = "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=";
      priority = 4;
    }
    {
      url = "https://yazi.cachix.org";
      publicKey = "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k=";
      priority = 5;
    }
    {
      url = "https://ghostty.cachix.org";
      publicKey = "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns=";
      priority = 6;
    }
    {
      url = "https://cache.nixos-cuda.org";
      publicKey = "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=";
      priority = 7;
    }
    {
      url = "zed.cachix.org";
      publicKey = "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU=";
      priority = 8;
    }
  ];
  nixConfig = {
    extra-trusted-public-keys = builtins.catAttrs "publicKey" substituters;
    extra-substituters = map (def: "${def.url}?priority=${toString def.priority}") substituters;
  };
in {
  flake.nixConfig = nixConfig;
  flake-file.nixConfig = nixConfig;
}
