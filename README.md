# My updated nix config now more 'dendritic'

I'm working on porting my [existing nix configuration](https://github.com/zmre/nix-config/) to a more modular and more ["dendritic"](https://github.com/mightyiam/dendritic) pattern where every file is a [flake-parts module](https://flake.parts/index.html).  Additionally, I'm using [flake-file](https://github.com/vic/flake-file/) to generate the flake.nix so that I can sprinkle inputs around inside of modules making them more self contained.

My current config is pretty large and has some pretty large files -- especially my home-manager/default.nix file.  It's also a bit messy when it comes to multi-host use.

I'm starting this port in a fresh repository because the changes are simply too extensive to mess with in a branch for the time being.

## Manual Building

`nix build '.#nixosConfigurations.avalon.config.system.build.toplevel'`

`nix build '.#darwinConfigurations.attolia.system'`

## Helpful Nix Command Flags

* `--extra-experimental-features 'nix-command flakes'`
* `--log-format raw` 
* `--verbose` 
* `--show-trace`

## Nix Verify

If you get segfaults, try this:

`nix-store --verify --check-contents --repair`


