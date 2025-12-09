# My updated nix config now more 'dendritic'

I'm working on porting my [existing nix configuration](https://github.com/zmre/nix-config/) to a more modular and more ["dendritic"](https://github.com/mightyiam/dendritic) pattern where every file is a [flake-parts module](https://flake.parts/index.html).  Additionally, I'm using [flake-file](https://github.com/vic/flake-file/) to generate the flake.nix so that I can sprinkle inputs around inside of modules making them more self contained.

My current config is pretty large and has some pretty large files -- especially my home-manager/default.nix file.  It's also a bit messy when it comes to multi-host use.

I'm starting this port in a fresh repository because the changes are simply too extensive to mess with in a branch for the time being.

## Automatic Building

Once first installed, there are aliases to use to deploy and update configs:

* On home-manager only installs (eg, aironcore): `hmswitch` and `hmupdate`
* On linux nixos machines (eg, avalon): `noswitch` and `noupdate`
* On mac machine (eg, attolia): `dwswitch` and `dwupdate`

## Flake File Generation

The flake is now built up from configs that are scattered across modules. This allows flake input specifications to sit with their configuration in a more logical place. To update the flake.nix file, use this command:

`nix run .#write-flake`

But note: this is done for you if you use the automatic switch/update aliases above.

## Manual Building

`nix build '.#nixosConfigurations.avalon.config.system.build.toplevel'`

`nix build '.#darwinConfigurations.attolia.system'`

## Manual Switching

Not sure you need to specify hostname since I think that's the default, but I always have, so here it is:

* `sudo darwin-rebuild switch --flake .#$(hostname -s)`
* `home-manager switch --flake .#$(hostname -s)`
* `sudo nixos-rebuild switch --flake .#$(hostname -s)`

## Full Building

## Helpful Nix Command Flags

* `--extra-experimental-features 'nix-command flakes'`
* `--log-format raw` 
* `--verbose` 
* `--show-trace`

## Nix Verify

If you get segfaults, try this:

`nix-store --verify --check-contents --repair`


## Module Architecture

### Module Types

This config uses three distinct module types, each exposed via `flake.*`:

1. **`flake.darwinModules.*`** - nix-darwin system modules (macOS only)
2. **`flake.nixosModules.*`** - NixOS system modules (Linux only)
3. **`flake.modules.homeManager.*`** - home-manager modules (cross-platform)

Then each host needs to reference the modules it wants in two places: home-manager list of modules and the os list of modules, if applicable.
