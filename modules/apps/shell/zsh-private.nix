{inputs, ...}: {
  flake.modules.homeManager.zsh-private = {lib, ...}: {
    # `zsh-priv` drops into a nested zsh session for working with secrets:
    # history stays in memory for that session only (up-arrow/ctrl-r still
    # work) but nothing is ever written to a history file, and atuin's hooks
    # are never installed -- it captures nothing rather than capturing and
    # discarding. atuin.nix disables enableZshIntegration and defers to the
    # guard below so private sessions never eval atuin's init at all, instead
    # of trying to tear its hooks down after the fact.
    programs.zsh.initContent = lib.mkMerge [
      ''
        if [[ -z "''${ZSH_PRIVATE:-}" ]]; then
          eval "$(atuin init zsh --disable-up-arrow)"
        fi

        zsh-priv() {
          ZSH_PRIVATE=1 zsh
        }
      ''
      (lib.mkAfter ''
        if [[ -n "''${ZSH_PRIVATE:-}" ]]; then
          unset HISTFILE
          SAVEHIST=0
        fi
      '')
    ];
  };
}
