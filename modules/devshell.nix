{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    # Default dev shell with tools for working on this config
    devShells.default = pkgs.mkShell {
      name = "nix-config-dev";
      buildInputs = with pkgs; [
        statix # Static Nix linter
        deadnix # Find unused Nix code
        nixfmt # Nix formatter
        nil # Nix LSP
      ];

      shellHook = ''
        # Symlink pre-commit hook if not already installed
        if [[ -f scripts/pre-commit && -d .git/hooks ]]; then
          if [[ ! -L .git/hooks/pre-commit ]]; then
            # Remove existing file if it's not a symlink
            rm -f .git/hooks/pre-commit 2>/dev/null || true
            ln -s ../../scripts/pre-commit .git/hooks/pre-commit
            echo "Installed pre-commit hook (symlink)"
          fi
        fi

        echo "Nix config development shell"
        echo "Available tools: statix, deadnix, nixfmt, nil"
        echo ""
        echo "Run 'statix check .' to lint Nix files"
        echo "Run 'nix flake show' to validate flake structure"
      '';
    };

    # Check that runs statix
    checks.statix = pkgs.runCommand "statix-check" {
      nativeBuildInputs = [pkgs.statix];
      src = inputs.self;
    } ''
      cd $src
      statix check .
      touch $out
    '';
  };
}
