#!/usr/bin/env bash
# Quick reference for exploring your Nix configuration with nix repl and eval

cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════╗
║           Nix Configuration Explorer - Quick Reference                 ║
╚════════════════════════════════════════════════════════════════════════╝

━━━ Interactive Exploration (nix repl) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Start repl and load your flake:
  $ nix repl
  nix-repl> :lf .

Explore Darwin configuration (attolia):
  nix-repl> outputs.darwinConfigurations.attolia.config.system.primaryUser
  nix-repl> outputs.darwinConfigurations.attolia.config.users.users
  nix-repl> outputs.darwinConfigurations.attolia.config.networking.hostName
  nix-repl> outputs.darwinConfigurations.attolia.config.homebrew.enable
  nix-repl> outputs.darwinConfigurations.attolia.config.homebrew.casks

Explore home-manager config:
  nix-repl> outputs.darwinConfigurations.attolia.config.home-manager.users.pwalsh.home
  nix-repl> outputs.darwinConfigurations.attolia.config.home-manager.users.pwalsh.programs

See all available attributes (use TAB completion):
  nix-repl> outputs.darwinConfigurations.attolia.config.<TAB>
  nix-repl> outputs.darwinConfigurations.attolia.config.system.<TAB>

Pretty-print entire attribute sets:
  nix-repl> :p outputs.darwinConfigurations.attolia.config.system
  nix-repl> :p outputs.darwinConfigurations.attolia.config.homebrew

Check available options (shows documentation):
  nix-repl> :p outputs.darwinConfigurations.attolia.options.system
  nix-repl> :p outputs.darwinConfigurations.attolia.options.homebrew

Useful repl commands:
  :lf .           - Load flake from current directory
  :r              - Reload the flake
  :p <expr>       - Pretty-print expression
  :t <expr>       - Show type of expression
  :q              - Quit repl

━━━ Quick One-Liners (nix eval) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Evaluate specific values:
  $ nix eval .#darwinConfigurations.attolia.config.system.primaryUser
  $ nix eval .#darwinConfigurations.attolia.config.networking.hostName

Check Homebrew configuration:
  $ nix eval .#darwinConfigurations.attolia.config.homebrew.enable
  $ nix eval .#darwinConfigurations.attolia.config.homebrew.casks --json | jq
  $ nix eval .#darwinConfigurations.attolia.config.homebrew.masApps --json | jq

List all modules loaded:
  $ nix eval .#darwinConfigurations.attolia.config._module.args --apply builtins.attrNames

Show full config as JSON (warning: large output):
  $ nix eval .#darwinConfigurations.attolia.config --json | jq '.' | less

With trace (for debugging evaluation errors):
  $ nix eval --show-trace .#darwinConfigurations.attolia.config.system.primaryUser

━━━ Exploring Available Outputs ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

List all flake outputs:
  $ nix flake show

List all packages available:
  $ nix flake show --json | jq '.packages'

━━━ Common Exploration Patterns ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Find where a value is set (in repl):
  nix-repl> :p outputs.darwinConfigurations.attolia.options.system.primaryUser
  # Look at "definitions" to see which file sets it

Check if a module option exists:
  nix-repl> outputs.darwinConfigurations.attolia.options.homebrew.user or null

See all user-defined modules:
  nix-repl> :p outputs.darwinModules
  nix-repl> :p outputs.modules.homeManager

━━━ Debugging Tips ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

If you get infinite recursion errors:
  - Use --show-trace to see where it happens
  - Check for circular references in config

If an attribute doesn't exist:
  - Use tab completion to explore available attributes
  - Check options to see if it needs to be enabled first

If values don't match expectations:
  - Use :p options.<path> to see all definitions and their sources
  - Check module evaluation order

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

# Make it easy to copy-paste common commands
echo ""
echo "Would you like to:"
echo "  1. Start nix repl now"
echo "  2. Show homebrew casks (JSON)"
echo "  3. Show system settings"
echo "  4. Show home-manager config"
echo "  5. Exit"
echo ""
read -p "Choose (1-5): " choice

case $choice in
    1)
        echo "Starting nix repl..."
        echo "Run: :lf ."
        nix repl
        ;;
    2)
        echo "Homebrew casks:"
        nix eval .#darwinConfigurations.attolia.config.homebrew.casks
        echo ""
        echo "Homebrew brews:"
        nix eval .#darwinConfigurations.attolia.config.homebrew.brews
        ;;
    3)
        echo "System settings:"
        echo "Primary User: $(nix eval .#darwinConfigurations.attolia.config.system.primaryUser 2>/dev/null || echo 'not set')"
        echo "Hostname: $(nix eval .#darwinConfigurations.attolia.config.networking.hostName 2>/dev/null || echo 'not set')"
        echo "Platform: $(nix eval .#darwinConfigurations.attolia.config.nixpkgs.hostPlatform 2>/dev/null || echo 'not set')"
        ;;
    4)
        echo "Home-Manager username:"
        nix eval .#darwinConfigurations.attolia.config.home-manager.users.pwalsh.home.username 2>/dev/null || echo "not available"
        echo ""
        echo "Home-Manager homeDirectory:"
        nix eval .#darwinConfigurations.attolia.config.home-manager.users.pwalsh.home.homeDirectory 2>/dev/null || echo "not available"
        ;;
    5|*)
        echo "Exiting..."
        ;;
esac
