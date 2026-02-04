# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal NixOS/nix-darwin configuration repository using a modern "dendritic" architecture where every file is a flake-parts module. The configuration manages multiple hosts across macOS and Linux platforms.

### Architecture Pattern

- **Dendritic Structure**: Uses [flake-parts](https://flake.parts/) modules throughout, following the [dendritic pattern](https://github.com/mightyiam/dendritic)
- **Auto-generated flake.nix**: The `flake.nix` file is auto-generated using [flake-file](https://github.com/vic/flake-file/). DO NOT EDIT IT DIRECTLY.
- **Distributed Inputs**: Flake inputs are declared within individual modules (not centralized), making modules self-contained
- **Module Tree**: Uses [import-tree](https://github.com/vic/import-tree) to automatically load modules from the directory structure

#### What is the Dendritic Pattern?

The dendritic pattern is "a Nix flake-parts usage pattern in which **every Nix file is a flake-parts module**." Key principles:

1. **Every file is a flake-parts module** - No exceptions
2. **One feature per file** - Each file implements a single, focused concern
3. **Span all applicable module classes** - Features work across NixOS, home-manager, and nix-darwin when relevant
4. **Path-based naming** - File location serves as the feature identifier
5. **Shared config system** - All files contribute to and read from flake-parts' config, avoiding `specialArgs` complexity

**Critical concept**: Modules contain ALL platform configurations within themselves. For example, a terminal module includes BOTH the Darwin config (using Homebrew) AND the NixOS config (using nix packages) in the same file. When a macOS host includes the module, only the Darwin parts apply; when a Linux host includes it, only the NixOS parts apply.

#### How flake-parts Works

flake-parts is "the core of a distributed framework for writing Nix Flakes." It provides:

- **Standard flake attributes** - Mirrors the Nix flake schema
- **System abstraction** - Proper handling of multi-platform concerns via `perSystem`
- **Module system** - Break your flake into focused, reusable modules
- **Shared config** - Values accessible across all modules without passing through specialArgs

#### How flake-file Works

flake-file **automates generation** of `flake.nix` from your modules:

1. Define flake attributes in any module using `flake-file.inputs.*`, `flake-file.description`, etc.
2. Run `nix run .#write-flake` to regenerate `flake.nix`
3. flake-file aggregates all distributed declarations into one file
4. Benefits: inputs live next to their usage, modules are self-documenting and portable

**Critical**: The generated `flake.nix` should never be edited directly - all changes go in module files.

### Directory Structure

```
.
├── flake.nix              # AUTO-GENERATED - use `nix run .#write-flake` to regenerate
├── dotfiles/              # Dotfiles (gitignore.nix)
└── modules/
    ├── base.nix           # Core config: systems, nixpkgs, overlays, stable pkgs
    ├── baseDarwin.nix     # Darwin module type definitions
    ├── baseHome.nix       # Home-manager integration
    ├── baseNixos.nix      # NixOS module type definitions (currently empty)
    ├── substituters.nix   # Binary cache configuration (cachix, cuda, etc.)
    │
    ├── hosts/             # Host-specific configurations
    │   ├── attolia.nix    # Primary macOS workstation (aarch64-darwin)
    │   ├── avalon.nix     # NixOS server/desktop (x86_64-linux, Framework Desktop)
    │   ├── volantis.nix   # NixOS laptop (x86_64-linux, Framework 11th-gen Intel)
    │   └── aironcore.nix  # Work machine home-manager only (x86_64-linux)
    │
    ├── apps/              # Application modules
    │   ├── ai.nix         # AI tools (aider, llm, etc.)
    │   ├── dev.nix        # Development tools (git, gh, languages)
    │   ├── filemanagement.nix  # File managers (yazi, lf)
    │   ├── hardened.nix   # Hardened/security-focused apps
    │   ├── iron.nix       # IronCore Labs tools (ironhide, ironoxide-cli)
    │   ├── network.nix    # Network utilities
    │   ├── prose.nix      # Writing tools
    │   ├── scripts.nix    # Custom shell scripts
    │   ├── security.nix   # Security tools
    │   ├── vim.nix        # Neovim config (pwnvim, pwneovide)
    │   ├── x-windows.nix  # X11/Wayland tools
    │   │
    │   ├── gui/           # GUI application modules
    │   │   ├── browsers.nix   # Web browsers (qutebrowser, Firefox, etc.)
    │   │   ├── comms-gui.nix  # Communication apps (Slack, Discord, etc.)
    │   │   ├── dev-gui.nix    # GUI dev tools (VSCode, etc.)
    │   │   ├── term-gui.nix   # Terminal emulators (Ghostty, WezTerm, etc.)
    │   │   └── window-mgmt.nix # Window management (aerospace, sketchybar)
    │   │
    │   ├── shell/         # Shell environment modules
    │   │   ├── default.nix       # Main shell config (packages, env vars)
    │   │   ├── atuin.nix         # Shell history
    │   │   ├── hackernews-tui.nix # HN terminal client
    │   │   ├── hardware-options.nix # GPU detection options
    │   │   ├── starship.nix      # Prompt config
    │   │   ├── tmux.nix          # Terminal multiplexer
    │   │   └── zsh.nix           # Zsh configuration
    │   │
    │   └── media/         # Media modules
    │       ├── default.nix   # Media players (mpv, etc.)
    │       ├── audnexus.nix  # Audiobook metadata
    │       └── comskip.nix   # Commercial skip for recordings
    │
    ├── services/          # System services
    │   ├── espanso.nix    # Text expansion
    │   ├── nfs-mounts.nix # NFS mount configuration
    │   ├── nginx-rtmp.nix # RTMP streaming server
    │   ├── ollama.nix     # Local LLM server
    │   ├── plex.nix       # Media server
    │   ├── protonmail-bridge-for-mobile.nix
    │   ├── search.nix     # Meilisearch
    │   ├── ssh.nix        # SSH server config
    │   └── tailscale.nix  # Mesh VPN
    │
    ├── system/            # System-level configuration
    │   ├── brew.nix       # Homebrew (Darwin only)
    │   ├── common.nix     # Common system settings
    │   ├── darwin-prefs.nix # macOS preferences
    │   ├── determinate.nix # Determinate Nix integration (Darwin + NixOS)
    │   ├── fonts.nix      # Font packages
    │   ├── keyboard.nix   # Keyboard settings
    │   ├── nix.nix        # Nix daemon settings (NixOS only; Darwin defers to Determinate)
    │   ├── remote-builders.nix # Distributed builds (NixOS only; Darwin uses Determinate's native Linux builder)
    │   ├── terminfo.nix   # Terminal info database
    │   ├── touchid.nix    # Touch ID for sudo (Darwin)
    │   └── ulimits.nix    # System limits
    │
    └── hardware/          # Hardware-specific modules
        ├── amd-gpu-tools.nix     # AMD ROCm tools
        ├── avalon-disk-config.nix # ZFS disk layout
        └── nvidia-gpu-tools.nix   # CUDA tools
```

## Common Commands

### Regenerating flake.nix

The `flake.nix` file is auto-generated. To regenerate after modifying modules:

```bash
nix run .#write-flake
```

### Building and Switching

```bash
# macOS (attolia)
darwin-rebuild switch --flake .#attolia

# NixOS (avalon)
sudo nixos-rebuild switch --flake .#avalon

# Home-manager only (aironcore)
home-manager switch --flake .#aironcore
```

### Other Commands

```bash
# Update flake inputs
nix flake update

# Check flake structure
nix flake show

# Build without switching
nix build .#darwinConfigurations.attolia.system
nix build .#nixosConfigurations.avalon.config.system.build.toplevel
```

## Module Architecture

### Module Types

This config uses three distinct module types, each exposed via `flake.*`:

1. **`flake.darwinModules.*`** - nix-darwin system modules (macOS only)
2. **`flake.nixosModules.*`** - NixOS system modules (Linux only)
3. **`flake.modules.homeManager.*`** - home-manager modules (cross-platform)

### How Hosts Compose Modules

Hosts import modules by referencing them from `inputs.self.*Modules` or `inputs.self.modules.homeManager.*`:

```nix
# Example from attolia.nix (Darwin host)
flake.darwinConfigurations.attolia = inputs.darwin.lib.darwinSystem {
  modules = with inputs.self.darwinModules; [
    attolia-config
    system
    brew
    # ... more darwin modules
  ];
};

# Home-manager is configured within the darwin/nixos config:
home-manager.users.pwalsh = {
  imports = with inputs.self.modules.homeManager; [
    shell
    vim
    dev
    # ... more home-manager modules
  ];
};
```

### Module Patterns

#### Darwin Module Pattern (`flake.darwinModules.*`)

```nix
{inputs, ...}: {
  # Declare inputs this module needs
  flake-file.inputs.some-tool.url = "github:owner/repo";

  flake.darwinModules.my-feature = {pkgs, config, ...}: {
    # Darwin-specific system config
    homebrew.casks = ["some-app"];
    # or nix packages
    environment.systemPackages = [pkgs.something];
  };
}
```

#### NixOS Module Pattern (`flake.nixosModules.*`)

```nix
{inputs, ...}: {
  flake.nixosModules.my-service = {pkgs, config, ...}: {
    services.something.enable = true;
    # NixOS-specific config
  };
}
```

#### Home-Manager Module Pattern (`flake.modules.homeManager.*`)

```nix
{inputs, ...}: {
  flake.modules.homeManager.my-app = {pkgs, config, lib, ...}: {
    # Cross-platform home-manager config
    home.packages = [pkgs.something];
    programs.something.enable = true;

    # Platform-specific within home-manager
    home.packages = lib.optionals pkgs.stdenv.isDarwin [pkgs.macos-only];
  };
}
```

### GPU-Aware Modules

Several modules adapt based on GPU type using a custom `hardware.gpu` option:

```nix
# Defined in hardware-options.nix
options.hardware.gpu = lib.mkOption {
  type = lib.types.enum ["none" "cuda" "rocm"];
  default = "none";
};

# Used in modules like ollama.nix, shell/default.nix:
ollamaPkg = if config.hardware.gpu == "cuda" then pkgs.ollama-cuda
            else if config.hardware.gpu == "rocm" then pkgs.ollama-rocm
            else pkgs.ollama;
```

Hosts set this option: `{hardware.gpu = "rocm";}` (avalon) or `{hardware.gpu = "cuda";}` (aironcore).

### Base Modules

- **`base.nix`** - Core setup: systems list, nixpkgs config, stable overlay (`pkgs.stable.*`)
- **`baseDarwin.nix`** - Defines `flake.darwinModules` option type and darwin input
- **`baseHome.nix`** - Imports home-manager flake module
- **`substituters.nix`** - Binary caches (cachix: zmre, nix-community, numtide, yazi, ghostty, nixos-cuda)

## Host Configurations

### attolia (aarch64-darwin)

Primary macOS workstation. Full-featured development environment.

- **Type**: `darwinConfigurations`
- **Platform**: Apple Silicon Mac
- **Nix**: Determinate Nix — `nix.enable = false` on Darwin; all nix settings managed via `determinateNix.customSettings` in `determinate.nix`. Native Linux builder replaces remote-builders.
- **Features**: Homebrew management, aerospace window manager, full GUI apps, home-manager

### avalon (x86_64-linux)

NixOS server/desktop running on Framework Desktop AMD AI Max 300.

- **Type**: `nixosConfigurations`
- **Platform**: AMD with ROCm GPU support
- **Nix**: Determinate Nix via NixOS module; `nix.nix` common settings still apply
- **Features**: ZFS, Plex, llama.cpp, nginx-rtmp, Tailscale, NFS mounts, SSH server
- **Hardware**: Uses nixos-hardware Framework module, disko for disk config

### volantis (x86_64-linux)

NixOS laptop on Framework 11th-gen Intel.

- **Type**: `nixosConfigurations`
- **Platform**: Intel with integrated graphics
- **Nix**: Determinate Nix via NixOS module
- **Features**: Full GUI desktop, security/hacking tools, Tailscale, fingerprint reader

### aironcore (x86_64-linux)

Work machine with home-manager only (no system-level NixOS control).

- **Type**: `homeConfigurations`
- **Platform**: x86_64 Linux with CUDA GPU
- **Nix**: Standard Nix (no Determinate — no system-level control)
- **Features**: Shell, dev tools, AI tools, vim - no GUI or system services

## Important Constraints

### DO NOT Edit flake.nix Directly

The file header states:
```nix
# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
```

Always make changes in module files under `modules/`, then regenerate.

### Declaring Inputs

To add a new flake input:
1. Add it to the appropriate module file using `flake-file.inputs.<name>.url`
2. Run `nix run .#write-flake` to regenerate `flake.nix`

Example pattern:
```nix
{inputs, ...}: {
  flake-file.inputs.pwnvim.url = "github:zmre/pwnvim";
  flake-file.inputs.pwneovide = {
    url = "github:zmre/pwneovide";
    inputs.pwnvim.follows = "pwnvim";
  };

  # Use the input
  flake.modules.homeManager.vim = {pkgs, ...}: {
    home.packages = [inputs.pwnvim.packages.${pkgs.system}.default];
  };
}
```

### Module Structure

Each module should be a valid flake-parts module function:
```nix
{inputs, ...}: {
  # Optional: declare inputs
  flake-file.inputs.something.url = "...";

  # Define modules for the appropriate system type
  flake.darwinModules.feature = { ... };      # Darwin system
  flake.nixosModules.feature = { ... };       # NixOS system
  flake.modules.homeManager.feature = { ... }; # Home-manager
}
```

## Migration Notes

This config was ported from https://github.com/zmre/nix-config/. Key differences from the old config:

| Aspect | Old Config | This Config (Dendritic) |
|--------|-----------|------------------------|
| **Inputs** | Centralized in flake.nix | Distributed across modules |
| **Home-Manager** | 87KB monolithic file | Multiple focused modules |
| **Module System** | Traditional imports | flake-parts modules |
| **flake.nix** | Hand-maintained | Auto-generated via flake-file |
| **Platform Configs** | Separated (darwin/, nixos/ dirs) | Combined in each module |

### What Was Ported

The migration from the old 87KB monolithic home-manager config is largely complete:

- ✅ Shell environment (zsh, atuin, starship, tmux, fzf, zoxide, direnv)
- ✅ Development tools (git, gh, languages, LSPs)
- ✅ Editors (neovim via pwnvim/pwneovide)
- ✅ File management (yazi, lf)
- ✅ AI tools (aider, llm, fabric)
- ✅ GUI apps (browsers, terminals, communication, dev tools)
- ✅ Darwin system (homebrew, preferences, touchid)
- ✅ NixOS system (avalon with services)
- ✅ Window management (aerospace, sketchybar)
- ✅ Media (mpv, plex)
- ✅ Security tools
- ✅ Network utilities

### Determinate Nix

This config uses [Determinate Nix](https://determinate.systems/) on all system-managed hosts (attolia, avalon, volantis). Key architectural points:

- **Darwin (attolia)**: `nix.enable = false` in `nix.nix` — nix-darwin does NOT manage `/etc/nix/nix.conf`. All nix settings are provided via `determinateNix.customSettings` in `modules/system/determinate.nix`. GC is handled automatically by Determinate's nixd.
- **NixOS (avalon, volantis)**: The Determinate NixOS module is imported alongside the existing `nix.nix` common settings. Both coexist.
- **aironcore**: Excluded — home-manager only, no system-level nix management.
- **Do NOT use `follows`** for the Determinate input — it causes cache misses per upstream recommendation.
- `nix-command` and `flakes` are stable in Determinate Nix. Only `pipe-operators` remains in `extra-experimental-features`.

### Remaining Items

- Parallels VM configs - not yet needed
- Some edge-case apps that may be missing
