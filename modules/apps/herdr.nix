{...}: {
  # herdr: terminal multiplexer / AI-agent orchestrator. Config and the glue
  # scripts its keybindings invoke both live here so all hosts get them.
  #
  # The upstream home-manager module writes config.toml as a read-only store
  # symlink, so herdr can no longer rewrite it (onboarding, `herdr config
  # reset-keys`). `onboarding = false` below keeps onboarding from firing.
  flake.modules.homeManager.herdr = {
    pkgs,
    lib,
    ...
  }: let
    herdrPkg = pkgs.herdr;

    # Pick a herdr CLI the running server will actually talk to. HERDR_BIN_PATH
    # is what the server injects into its own panes, so in normal operation it
    # is correct by construction. The store path is the fallback for CLI
    # invocation outside a pane.
    #
    # There is deliberately no third candidate. The old hand-written scripts
    # hardcoded a herdr-0.7.5 store path to survive version skew (nix upgrades
    # the profile while an older server keeps running and rejects the newer
    # client with protocol_mismatch). Nix cannot know the *previous* store path,
    # so a herdr upgrade now requires restarting the server. Fail loudly saying so.
    pickHerdr = ''
      herdr=""
      for cand in "''${HERDR_BIN_PATH:-}" ${lib.getExe herdrPkg}; do
        [ -n "$cand" ] || continue
        if "$cand" pane current >/dev/null 2>&1; then herdr="$cand"; break; fi
      done
      if [ -z "$herdr" ]; then
        echo "herdr: no reachable server, or the running server is older than this client." >&2
        echo "  Fix: herdr server stop && herdr" >&2
        exit 1
      fi
    '';

    # Floating tuicr overlay for the focused herdr agent pane.
    #
    # Bound to prefix+v as a type="popup" command. herdr injects
    # HERDR_ACTIVE_PANE_CWD (the focused pane's cwd), so the overlay always
    # reviews the repo that agent is working in.
    #
    #   dirty tree -> tuicr -w   straight to the agent's uncommitted diff
    #   clean tree -> tuicr      commit selector, so there is something to review
    #   no repo    -> tuicr's own hint, held open until you press enter
    tuicr-overlay = pkgs.writeShellApplication {
      name = "herdr-tuicr-overlay";
      runtimeInputs = [pkgs.git pkgs.tuicr];
      # The original ran under `set -uo pipefail` with errexit deliberately off:
      # `tuicr || hold` and the bare `git status` probe both rely on a non-zero
      # exit not killing the script.
      bashOptions = ["nounset" "pipefail"];
      text = ''
        dir="''${HERDR_ACTIVE_PANE_CWD:-$PWD}"

        hold() {
          # A popup dies the instant its command exits, so error text needs a
          # pause to be readable at all.
          printf '\n[%s]\npress enter to close ' "$dir"
          read -r _
        }

        cd "$dir" 2>/dev/null || { printf 'cannot cd to %s' "$dir"; hold; exit 1; }

        # Non-git checkouts (jj, hg) still work — let tuicr decide, and only hold
        # the popup open if it turns out not to be a repository at all.
        if ! git rev-parse --git-dir >/dev/null 2>&1; then
          tuicr || hold
          exit 0
        fi

        # --porcelain covers staged, unstaged, and untracked; tuicr counts all
        # three as reviewable working-tree changes.
        if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
          exec tuicr --working-tree
        fi

        # Clean tree: -w would abort with "No changes to review", so open the
        # commit selector instead and pick what to look at.
        exec tuicr
      '';
    };

    # Toggle a zoomed tuicr pane for the focused agent: open -> reveal ->
    # dismiss, one instance per workspace. Bound to prefix+shift+v as
    # type = "shell".
    #
    # Why a pane instead of type = "popup": a herdr popup is session-modal and
    # takes every keystroke, including the prefix, so no hotkey can ever dismiss
    # it — only the popup's own command exiting closes it. A normal pane keeps
    # herdr's key handling, so a single key toggles both ways; zooming it gives
    # the fullscreen overlay look.
    tuicr-toggle = pkgs.writeShellApplication {
      name = "herdr-tuicr-toggle";
      runtimeInputs = [pkgs.jq pkgs.coreutils];
      bashOptions = ["nounset" "pipefail"];
      # SC2016: the jq programs below are single-quoted on purpose — $L, $cur
      # and friends are jq variables, not shell ones.
      excludeShellChecks = ["SC2016"];
      text = ''
        LABEL="tuicr"
        OVERLAY="${lib.getExe tuicr-overlay}"

        ${pickHerdr}

        ws="''${HERDR_ACTIVE_WORKSPACE_ID:-}"
        target="''${HERDR_ACTIVE_PANE_ID:-}"
        cwd="''${HERDR_ACTIVE_PANE_CWD:-$HOME}"

        # Is there already a tuicr pane in this workspace? "<focused> <pane_id>".
        found=""
        if [ -n "$ws" ]; then
          found="$("$herdr" pane list --workspace "$ws" 2>/dev/null \
            | jq -r --arg L "$LABEL" '.result.panes[]? | select(.label == $L)
                                      | "\(.focused) \(.pane_id)"' 2>/dev/null | head -n1)"
        fi

        if [ -n "$found" ]; then
          focused="''${found%% *}"
          pid="''${found#* }"
          # Showing it -> dismiss; focus moved elsewhere -> reveal.
          # HERDR_ACTIVE_PANE_ID is the pane that was focused when the key fired,
          # which is the authoritative answer at keypress time; .focused is the
          # fallback for CLI invocation.
          if [ "$focused" = "true" ] || [ "$target" = "$pid" ]; then
            exec "$herdr" pane close "$pid"
          fi
          # `--pane <id>` matters: `pane zoom <id> --on` ignores the positional
          # and zooms whatever is current. The flag form also moves focus.
          exec "$herdr" pane zoom --pane "$pid" --on
        fi

        # Nothing here yet: split off the agent's pane so the new pane inherits
        # its cwd.
        args=(pane split --direction right --cwd "$cwd" --env "HERDR_ACTIVE_PANE_CWD=$cwd" --focus)
        [ -n "$target" ] && args+=(--pane "$target")
        pid="$("$herdr" "''${args[@]}" 2>/dev/null | jq -r '.result.pane.pane_id // empty')"
        [ -n "$pid" ] || exit 1

        "$herdr" pane rename "$pid" "$LABEL" >/dev/null 2>&1
        "$herdr" pane zoom --pane "$pid" --on >/dev/null 2>&1

        # `pane run` types its argv into the pane's shell as a plain line —
        # quotes are stripped, so keep it space-separated and unquoted. The
        # overlay is a self-contained executable, so no `bash` prefix is needed.
        # `exec` replaces the shell, so quitting tuicr exits the pane process and
        # herdr closes the pane; "pane exists" therefore always means "tuicr is
        # open".
        sleep 0.2
        exec "$herdr" pane run "$pid" exec "$OVERLAY"
      '';
    };

    # Jump to the next/previous agent that needs attention.
    #
    # Bound to prefix+a / prefix+shift+a. Replaces herdr's built-in next_agent,
    # which cycles every agent including the ones happily working. The built-ins
    # are unbound in settings.keys below so these can take the keys.
    #
    # Usage: herdr-agent-attention [next|prev]
    #
    # "Needs attention" = blocked (waiting on you) or done (finished). Override
    # AGENT_ATTENTION_STATES to taste — the values herdr reports are idle,
    # working, blocked, done, unknown.
    agent-attention = pkgs.writeShellApplication {
      name = "herdr-agent-attention";
      runtimeInputs = [pkgs.jq];
      bashOptions = ["nounset" "pipefail"];
      excludeShellChecks = ["SC2016"];
      text = ''
        STATES="''${AGENT_ATTENTION_STATES:-[\"blocked\",\"done\"]}"
        dir="''${1:-next}"

        ${pickHerdr}

        # Where we are now. HERDR_ACTIVE_PANE_ID is the pane that was focused
        # when the key fired; pane current is the fallback for CLI invocation.
        cur="''${HERDR_ACTIVE_PANE_ID:-}"
        [ -n "$cur" ] || cur="$("$herdr" pane current 2>/dev/null | jq -r '.result.pane.pane_id // empty')"

        # Two rings, in order of preference:
        #
        #   1. agents needing attention, oldest wait first (state_change_seq
        #      ascending), so one press lands on whoever has been stuck longest;
        #   2. if none need attention, every agent in sidebar order — plain
        #      next/previous down the panel, the way the built-in next_agent
        #      behaves.
        #
        # Ring 2 ranks by position in the snapshot's panes[] array, which is
        # grouped by space in sidebar order. Do NOT sort by
        # workspace_id/tab_id/pane_id instead: ids are creation order, and a
        # space whose tabs have been rearranged reports e.g. w9:t2 before w9:t1,
        # so id sort walks that space in an order that doesn't match what you see.
        #
        # To make ring 1 follow the sidebar too, change its sort_by to just .ord.
        #
        # Either way, position comes from the current pane. If it isn't in the
        # ring (you're on a tuicr pane, or on a working agent while ring 1 is in
        # play), a next starts at the head and a prev at the tail.
        target="$("$herdr" api snapshot 2>/dev/null | jq -r \
          --arg cur "$cur" --arg dir "$dir" --argjson states "$STATES" '
            def pick($a):
              if ($a | length) == 0 then null else
                ([ $a | to_entries[] | select(.value.pane_id == $cur) | .key ] | first) as $i
                | (if $i == null then
                     (if $dir == "prev" then (($a | length) - 1) else 0 end)
                   else
                     (if $dir == "prev" then (($i - 1 + ($a | length)) % ($a | length))
                      else (($i + 1) % ($a | length)) end)
                   end) as $n
                | $a[$n].pane_id
              end;
            .result.snapshot as $snap
            | ([ $snap.panes[]? | .pane_id ] | to_entries
               | map({ key: .value, value: .key }) | from_entries) as $rank
            | [ $snap.agents[]? | select(.agent != null)
                | . + { ord: ($rank[.pane_id] // 99999) } ] as $all
            | [ $all[] | select(.agent_status as $s | $states | index($s)) ] as $att
            | pick($att | sort_by(.state_change_seq, .ord)) as $t
            # $t == $cur means you are the only agent needing attention, so the
            # press would go nowhere; walk everyone instead.
            | (if $t != null and $t != $cur then $t
               else pick($all | sort_by(.ord)) end)
            | if . == null then empty else . end' 2>/dev/null)"

        if [ -n "$target" ]; then
          exec "$herdr" agent focus "$target"
        fi

        # Only reachable when there are no agents at all.
        "$herdr" notification show "No agents to jump to" >/dev/null 2>&1
      '';
    };
  in {
    programs.herdr = {
      enable = true;
      package = herdrPkg;

      settings = {
        onboarding = false;

        ui = {
          # Show detected/reported agent labels in split pane borders when no
          # manual pane name is set.
          show_agent_labels_on_pane_borders = true;
          # "spaces" (grouped by space) or "priority" (attention queue).
          agent_panel_sort = "spaces";
          # Ask the OS notification service directly, rather than in-app toasts.
          toast.delivery = "system";
        };

        theme = {
          name = "one-dark";
          auto_switch = false;
        };

        keys = {
          # prefix+a / prefix+shift+a walk the attention queue instead — see the
          # agent-attention bindings below. The built-ins cycle every agent
          # including the ones still working, so they stay unbound.
          next_agent = "";
          previous_agent = "";
          split_vertical = "prefix+|";

          command =
            [
              {
                key = "prefix+f";
                type = "plugin_action";
                command = "herdr-floax.toggle";
                description = "Toggle floating pane";
              }
              # tuicr review overlay for the focused agent. type = "popup" is
              # herdr's own session-modal floating terminal: it draws over the
              # layout without splitting or changing the tab.
              {
                key = "prefix+v";
                type = "popup";
                command = lib.getExe tuicr-overlay;
                description = "Review focused agent's diff in tuicr";
                width = "90%";
                height = "90%";
              }
              # Same review, as a toggleable zoomed pane instead of a popup. A
              # popup swallows the prefix, so nothing but its own command exiting
              # can close it. A pane keeps herdr's key handling, so this key both
              # opens and dismisses, one instance per workspace.
              {
                key = "prefix+shift+v";
                type = "shell";
                command = lib.getExe tuicr-toggle;
                description = "Toggle tuicr review pane for focused agent";
              }
              # Attention queue: walk the agents that are blocked (waiting on you)
              # or done (finished), oldest wait first, wrapping at the end. When
              # nothing needs attention — or you are the only one that does — it
              # degrades to plain next/previous over every agent, so the key always
              # moves you somewhere.
              {
                key = "prefix+a";
                type = "shell";
                command = "${lib.getExe agent-attention} next";
                description = "Next agent needing attention (else next agent)";
              }
              {
                key = "prefix+shift+a";
                type = "shell";
                command = "${lib.getExe agent-attention} prev";
                description = "Previous agent needing attention (else previous)";
              }
            ]
            # Same jump, no prefix. herdr parses cmd/super fine; whether the
            # keystroke ever reaches herdr is up to WezTerm, which only forwards
            # SUPER-modified keys when the app negotiates the kitty keyboard
            # protocol (config.enable_kitty_keyboard = true in wezterm.lua). If
            # this never fires, remap it WezTerm-side to a chord herdr always sees.
            #
            # Darwin only: on Linux herdr reads cmd as super, which the window
            # manager generally swallows before herdr sees it.
            #
            # There is deliberately no cmd+shift+a counterpart: WezTerm delivers
            # that chord as a bare "a", which lands as literal text in the focused
            # agent's pane. Use prefix+shift+a to go backwards.
            ++ lib.optionals pkgs.stdenv.isDarwin [
              {
                key = "cmd+a";
                type = "shell";
                command = "${lib.getExe agent-attention} next";
                description = "Next agent needing attention";
              }
            ];
        };

        experimental = {
          # Save recent pane screen history across full server restarts.
          pane_history = false;
        };
      };
    };
  };
}
