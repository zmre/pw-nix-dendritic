# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal NixOS/nix-darwin configuration repository using a modern "dendritic" architecture where every file is a flake-parts module. This represents a port from an older, larger monolithic configuration to a more modular structure.

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

**Critical concept**: Modules contain ALL platform configurations within themselves. For example, a `wezterm.nix` module would include BOTH the Darwin config (using Homebrew) AND the NixOS config (using nix packages) in the same file. When a macOS host includes the module, only the Darwin parts apply; when a Linux host includes it, only the NixOS parts apply.

This solves traditional Nix config problems: managing multiple machines, sharing modules selectively, handling cross-cutting concerns, and accessing values across different module systems (NixOS vs home-manager vs nix-darwin).

#### How flake-parts Works

flake-parts is "the core of a distributed framework for writing Nix Flakes." It provides:

- **Standard flake attributes** - Mirrors the Nix flake schema
- **System abstraction** - Proper handling of multi-platform concerns via `perSystem`
- **Module system** - Break your flake into focused, reusable modules
- **Shared config** - Values accessible across all modules without passing through specialArgs

Instead of one monolithic `flake.nix`, you write small modules that compose together.

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
├── flake.nix          # AUTO-GENERATED - use `nix run .#write-flake` to regenerate
├── modules/           # All flake-parts modules
│   ├── base.nix       # Base configuration (systems, global settings, pkgs setup)
│   ├── apps/          # Application-specific modules (e.g., vim.nix)
│   └── hosts/         # Host-specific configurations (e.g., attolia.nix)
└── dotfiles/          # Dotfiles directory (currently empty)
```

## Common Commands

### Regenerating flake.nix

The `flake.nix` file is auto-generated. To regenerate after modifying modules:

```bash
nix run .#write-flake
```

### Building Configurations

This repository supports multiple systems defined in `modules/base.nix`:
- `aarch64-darwin`
- `aarch64-linux`
- `x86_64-darwin`
- `x86_64-linux`

Standard Nix flake commands apply:

```bash
# Build a specific output
nix build .#<output>

# Update flake inputs
nix flake update

# Check flake structure
nix flake show
```

## Module Architecture

### Base Module (`modules/base.nix`)

The base module sets up:
- Supported systems across Darwin and Linux platforms
- Flake description and metadata
- nixConfig with allowUnfree, experimental features, and binary cache configuration
- perSystem arguments including `pkgs` with allowUnfree enabled
- Custom cachix substituters: zmre, yazi, ghostty

### Application Modules (`modules/apps/`)

Application modules declare their own flake inputs inline. For example, `vim.nix` declares:
- `pwnvim` input (github:zmre/pwnvim)
- `pwneovide` input (github:zmre/pwneovide)

This pattern makes modules portable and self-documenting.

**Important**: Application modules should contain **all platform configurations** for that app in one file. For example, a terminal emulator module would include both the Darwin Homebrew installation config AND the NixOS package config. Hosts automatically get only the relevant parts based on their platform.

### Host Modules (`modules/hosts/`)

Host-specific configurations go here (e.g., `attolia.nix`). Currently minimal as the port is in progress.

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

Example pattern from `modules/apps/vim.nix`:
```nix
{
  flake-file.inputs.pwnvim.url = "github:zmre/pwnvim";
  flake-file.inputs.pwneovide.url = "github:zmre/pwneovide";
}
```

### Module Structure

Each module should be a valid flake-parts module function:
```nix
{inputs, ...}: {
  # module configuration
}
```

The `inputs` argument provides access to all flake inputs, and the module can declare additional inputs via `flake-file.inputs.*`.

## Migration Context: Porting from Old Nix Config

This is an **active port** from the older configuration at https://github.com/zmre/nix-config/. This section documents what needs to be migrated and how to approach it.

### Old Configuration Structure

The old config (27 Nix files total) is organized with **platform separation** (darwin/ and nixos/ directories):

```
zmre/nix-config/
├── flake.nix (centralized inputs & outputs)
├── modules/
│   ├── common.nix (shared cross-system settings)
│   ├── overlays.nix (package overlays)
│   ├── darwin/                          ← Platform-specific directory
│   │   ├── default.nix
│   │   ├── core.nix
│   │   ├── brew.nix (100+ casks, 50+ Mac App Store apps)
│   │   ├── pam.nix
│   │   └── preferences.nix
│   ├── nixos/                           ← Platform-specific directory
│   │   └── default.nix
│   ├── hardware/
│   │   ├── framework-volantis.nix (Framework laptop)
│   │   ├── parallels-*.nix (VM configurations)
│   │   └── volantis.nix
│   └── home-manager/                    ← Platform-agnostic but monolithic
│       ├── default.nix (87KB! - THE BIG ONE)
│       ├── home-darwin.nix              ← Platform-specific
│       ├── home-linux.nix               ← Platform-specific
│       ├── home-security.nix
│       ├── shell-scripts.nix
│       └── dotfiles/gitignore.nix
└── nix-shells/security/ (isolated security tools)
```

**Note**: The old config **separates platforms into different directories** (darwin/, nixos/). The new dendritic approach **combines platform configs within each feature module**.

### Host Configurations to Port

The old config manages multiple hosts:

1. **attolia** (aarch64-darwin) - Primary macOS workstation
   - Uses nix-homebrew with extensive Homebrew cask management
   - Home-manager with Darwin-specific modules

2. **volantis** (x86_64-linux) - Framework laptop
   - NixOS configuration with nixos-hardware integration
   - Security modules enabled

3. **nixos** (aarch64-linux) - Parallels ARM VM
   - Basic NixOS setup

4. **nixos-pw-vm** (x86_64-linux) - Parallels x86 VM
   - Standard home-manager modules

### The 87KB Home-Manager Monster

The `modules/home-manager/default.nix` file is the primary challenge - it contains a comprehensive, monolithic configuration with:

**Development Environment:**
- Text editors: Neovim (primary), VSCode with extensions, Zed (disabled)
- Language servers: Rust, Python, Node.js, Scala, Nix, and more
- Version control: Git with extensive aliases, difftastic, GitHub CLI with extensions
- Shell: Zsh (vi-mode), Nushell, custom functions and aliases
- Terminal: Starship prompt, Alacritty, Kitty configurations

**System Tools:**
- File management: Yazi (modern), lf (legacy)
- Multiplexing: tmux with Vi keybindings
- Navigation: fzf, zoxide, direnv
- Shell history: atuin

**Utilities & Applications:**
- Productivity: espanso text expansion
- Media: mpv player
- RSS: newsboat
- Compression: multiple format utilities
- Network tools: various CLI utilities

**Key Characteristics:**
- Keyboard-driven workflow with Vi keybindings everywhere
- Conditional macOS-specific configs (aerospace, colima, Docker)
- Custom environment variables for editors and terminals
- Project navigation functions

### Flake Inputs to Port

The old config has **extensive inputs** including:

**Core Nix:**
- nixpkgs (unstable + stable variants)
- nixpkgs-stable-darwin
- home-manager
- nix-darwin
- nix-homebrew (with tap management)

**Personal Projects:**
- pwnvim, pwneovide (already ported in `modules/apps/vim.nix`)
- gtm-okr, babble-cli, gh-worktree
- pwai (private AI assistant)

**Third-party Tools:**
- yazi (file manager)
- ghostty (terminal)
- Various GitHub CLI extensions
- NUR (Nix User Repository) for Firefox extensions
- StevenBlack hosts blocklist

### Porting Strategy

The dendritic pattern requires breaking the monolith into focused, feature-based modules where **each module contains all platform-specific logic within itself**.

**Recommended Module Breakdown:**

```
modules/
├── base.nix (already exists - common settings)
├── hosts/
│   ├── attolia.nix (macOS workstation - includes platform-agnostic modules)
│   ├── volantis.nix (Framework laptop - includes platform-agnostic modules)
│   └── nixos-vms.nix (VM configs)
├── apps/
│   ├── vim.nix (already exists - Neovim)
│   ├── git.nix (Git + GitHub CLI + difftastic)
│   ├── vscode.nix (VSCode + extensions)
│   ├── wezterm.nix (Darwin brew config + NixOS package config)
│   ├── alacritty.nix (cross-platform terminal config)
│   ├── kitty.nix (cross-platform terminal config)
│   ├── ghostty.nix (cross-platform terminal config)
│   ├── shell.nix (Zsh, Nushell, Starship - works on all platforms)
│   ├── tmux.nix (cross-platform)
│   ├── yazi.nix (file manager - cross-platform)
│   ├── fzf.nix (cross-platform)
│   ├── mpv.nix (media player - cross-platform)
│   └── newsboat.nix (RSS reader - cross-platform)
├── system/
│   ├── homebrew.nix (Darwin-only: brew, casks, Mac App Store)
│   ├── darwin-preferences.nix (macOS system preferences)
│   └── darwin-pam.nix (Darwin PAM config)
├── hardware/
│   ├── framework-volantis.nix (NixOS-only: Framework laptop hardware)
│   └── parallels.nix (VM-specific configs)
└── security/
    └── tools.nix (security tools - may have platform-specific sections)
```

**Each module should:**
1. Be a flake-parts module: `{inputs, ...}: { ... }`
2. Declare its own flake inputs via `flake-file.inputs.*`
3. Focus on a single feature/concern
4. **Contain ALL platform configs for that feature** (Darwin, NixOS, home-manager)
5. Use conditional logic to apply only relevant parts per platform
6. Use the file path as its identifier

**Platform-Agnostic Module Pattern:**

A typical cross-platform module like `apps/wezterm.nix`:

```nix
{inputs, ...}: {
  flake-file.inputs.wezterm.url = "github:wez/wezterm";

  # Darwin-specific: install via Homebrew
  darwinConfigurations.attolia.homebrew.casks = ["wezterm"];

  # NixOS-specific: install via nix packages
  nixosConfigurations.volantis.environment.systemPackages = [inputs.wezterm];

  # home-manager config (works on both platforms)
  home-manager.users.pwalsh.programs.wezterm = {
    enable = true;
    # shared config here
  };
}
```

This way, both `attolia` (macOS) and `volantis` (Linux) can include the same `wezterm.nix` module, and each gets only what's relevant to their platform.

**Migration Approach:**
1. Start with self-contained, cross-platform apps (git, tmux, individual programs)
2. Port inputs into their respective modules
3. Include both Darwin and NixOS configs in each module (where applicable)
4. Extract truly shared settings into base module
5. Handle host-specific overrides in `modules/hosts/`
6. Test incrementally on both platforms - don't migrate everything at once
7. Maintain reference to old config until port is complete

### Key Differences: Old vs New

| Aspect | Old Config | New Config (Dendritic) |
|--------|-----------|------------------------|
| **Inputs** | Centralized in flake.nix | Distributed across modules |
| **Home-Manager** | 87KB monolithic file | Multiple focused modules |
| **Module System** | Traditional imports | flake-parts modules |
| **flake.nix** | Hand-maintained | Auto-generated via flake-file |
| **Feature Discovery** | Read large files | Check directory structure |
| **Sharing Values** | specialArgs/extraArgs | flake-parts config system |
| **Platform Configs** | Separated (darwin/, nixos/ dirs) | Combined in each module |

### Porting Guidelines

When migrating from the old config:

1. **Don't copy-paste large sections** - Break them down by feature/program
2. **Keep inputs close to usage** - If a module uses yazi, that module declares the yazi input
3. **One feature per file** - Don't create another monolith
4. **Combine platform configs in each module** - Don't separate Darwin and NixOS into different directories; put both in the same module file
5. **Use conditional logic** - Leverage NixOS/Darwin-specific options so each platform gets only what it needs
6. **Test per module on both platforms** - If a module supports multiple platforms, verify it works on each
7. **Preserve working config** - Keep old config functional during migration
8. **Document decisions** - Note why certain configs are grouped together

**Example of combining platforms in one module:**

Instead of creating `modules/darwin/git.nix` and `modules/nixos/git.nix`, create one `modules/apps/git.nix` that contains:

```nix
{inputs, pkgs, ...}: {
  flake-file.inputs.difftastic.url = "github:wilfred/difftastic";

  # Works on both platforms
  home-manager.users.pwalsh.programs.git = {
    enable = true;
    userName = "Patrick Walsh";
    # ... shared config
  };

  # Darwin-specific (if needed)
  darwinConfigurations.attolia = {
    # Darwin-specific git config
  };

  # NixOS-specific (if needed)
  nixosConfigurations.volantis = {
    # NixOS-specific git config
  };
}
```

### Current Port Status

✅ **Completed:**
- Base architecture (flake-file, dendritic structure)
- Vim/Neovim inputs (pwnvim, pwneovide)
- Base system configuration
- Multi-platform support setup

⏳ **In Progress:**
- Host configurations (attolia is stubbed)

❌ **Not Yet Started:**
- Home-manager module breakdown
- Darwin-specific configs (Homebrew, system preferences)
- NixOS configurations
- Hardware-specific modules
- Security tools
- Most application configurations
- Shell environment
- Development tools
