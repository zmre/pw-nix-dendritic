#!/usr/bin/env bash
# =============================================================================
# cleanup-dev-disk.sh
# Cleans up Nix (darwin + home-manager), Colima/Docker, and Rust dev artifacts
#
# Usage:
#   ./cleanup-dev-disk.sh           # dry-run (safe, shows what WOULD be freed)
#   ./cleanup-dev-disk.sh --run     # actually execute cleanup
#   ./cleanup-dev-disk.sh --run --section nix
#   ./cleanup-dev-disk.sh --run --section docker
#   ./cleanup-dev-disk.sh --run --section rust
# =============================================================================

set -euo pipefail

# ── Flags ─────────────────────────────────────────────────────────────────────
DRY_RUN=true
SECTION="all"   # nix | docker | rust | all

for arg in "$@"; do
  case $arg in
    --run)     DRY_RUN=false ;;
    --section) ;;                         # handled by shift below
    nix|docker|rust|all) SECTION="$arg" ;;
  esac
done

# Re-parse properly
while [[ $# -gt 0 ]]; do
  case $1 in
    --run)               DRY_RUN=false ; shift ;;
    --section)           SECTION="$2"  ; shift 2 ;;
    --section=*)         SECTION="${1#*=}" ; shift ;;
    *) shift ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════${RESET}"; \
            echo -e "${BOLD}${CYAN}  $1${RESET}"; \
            echo -e "${BOLD}${CYAN}══════════════════════════════════════${RESET}"; }
info()    { echo -e "  ${GREEN}▶${RESET} $*"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
dryrun()  { echo -e "  ${YELLOW}[DRY-RUN]${RESET} $*"; }
skipped() { echo -e "  ${YELLOW}↷ skipped:${RESET} $*"; }

disk_usage() {
  # Returns human-readable size of a path (or "0B" if absent)
  if [[ -e "$1" ]]; then
    du -sh "$1" 2>/dev/null | awk '{print $1}'
  else
    echo "0B (not found)"
  fi
}

run_cmd() {
  # Wraps a command: prints it in dry-run, executes it otherwise
  if $DRY_RUN; then
    dryrun "$*"
  else
    info "Running: $*"
    eval "$*" || warn "Command exited with error (continuing): $*"
  fi
}

# ── Preamble ──────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}Dev Disk Cleanup${RESET}"
if $DRY_RUN; then
  warn "DRY-RUN mode — nothing will be changed. Pass --run to execute."
else
  warn "LIVE mode — changes are permanent."
  echo -e "  Press ${BOLD}Ctrl-C${RESET} within 5 seconds to abort..."
  sleep 5
fi

# =============================================================================
# NIX
# =============================================================================
cleanup_nix() {
  header "Nix (darwin + home-manager)"

  # Prevent nix/home-manager from opening a pager (less/more)
  export NIX_PAGER=cat
  export PAGER=cat

  # ── 1. Home-manager: remove old generations ─────────────────────────────
  info "home-manager: current generations"
  home-manager generations 2>/dev/null | head -10 || skipped "home-manager not found in PATH"

  if command -v home-manager &>/dev/null; then
    info "home-manager: removing all but the current generation"
    run_cmd "home-manager expire-generations '-0 days'"
  else
    skipped "home-manager not in PATH — skipping expire-generations"
  fi

  # ── 2. Nix profiles: remove old generations ──────────────────────────────
  if command -v nix-env &>/dev/null; then
    info "nix-env: listing profile generations"
    nix-env --list-generations 2>/dev/null | cat
    info "nix-env: deleting all but current generation"
    run_cmd "nix-env --delete-generations old"
  else
    skipped "nix-env not found"
  fi

  # Remove system profile old generations (darwin-rebuild)
  if [[ -e /nix/var/nix/profiles/system ]]; then
    info "nix system profile: deleting old generations"
    run_cmd "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old"
  fi

  # ── 3. nix-collect-garbage ───────────────────────────────────────────────
  echo
  warn "Measuring /nix/store size via du — may take a few minutes on a large store..."
  info "Store size before GC: $(disk_usage /nix/store)"
  info "Running nix-collect-garbage (--delete-older-than 7d)"
  run_cmd "sudo nix-collect-garbage --delete-older-than 7d"
  if ! $DRY_RUN; then
    info "Store size after GC:  $(disk_usage /nix/store)"
  fi

  # ── 4. nix store --optimise (deduplication via hard-links) ───────────────
  info "Optimising store (hard-link deduplication) — this can take a while"
  run_cmd "sudo nix store --optimise"

  # ── 5. Nix flake cache ───────────────────────────────────────────────────
  FLAKE_CACHE="$HOME/.cache/nix"
  info "Flake eval cache: $(disk_usage "$FLAKE_CACHE")"
  read -rp "  Clear flake eval cache? [y/N] " yn
  if [[ "${yn,,}" == "y" ]]; then
    run_cmd "rm -rf '$FLAKE_CACHE'"
  else
    skipped "flake eval cache kept"
  fi

  # ── 6. Nix download cache ────────────────────────────────────────────────
  NIX_DL_CACHE="/root/Library/Caches/nix"         # macOS daemon user
  info "Checking daemon download cache: $NIX_DL_CACHE"
  if [[ -d "$NIX_DL_CACHE" ]]; then
    info "Size: $(disk_usage "$NIX_DL_CACHE")"
    warn "This is the daemon's cache; clearing requires sudo"
    run_cmd "sudo rm -rf '$NIX_DL_CACHE'"
  fi

  # Also check user-level nix cache
  USER_NIX_CACHE="$HOME/Library/Caches/nix"
  if [[ -d "$USER_NIX_CACHE" ]]; then
    info "User nix cache: $(disk_usage "$USER_NIX_CACHE")"
    run_cmd "rm -rf '$USER_NIX_CACHE'"
  fi

  # ── 7. direnv / nix-direnv cached envs ──────────────────────────────────
  DIRENV_CACHE="$HOME/.cache/direnv"
  if [[ -d "$DIRENV_CACHE" ]]; then
    info "direnv cache: $(disk_usage "$DIRENV_CACHE")"
    run_cmd "rm -rf '$DIRENV_CACHE'"
  fi

  echo -e "\n  ${GREEN}Nix cleanup done.${RESET}"
}

# =============================================================================
# DOCKER / COLIMA
# =============================================================================
cleanup_docker() {
  header "Docker via Colima"

  # ── Check colima is running ───────────────────────────────────────────────
  COLIMA_RUNNING=false
  if colima status 2>/dev/null | grep -q "running"; then
    COLIMA_RUNNING=true
    info "Colima is running — docker commands will work"
  else
    warn "Colima does not appear to be running."
    warn "Start it with: colima start"
    warn "Attempting docker commands anyway (might use another socket)..."
  fi

  # ── 1. Docker system prune ────────────────────────────────────────────────
  info "Stopped containers, dangling images, unused networks, build cache:"
  if $DRY_RUN; then
    dryrun "docker system df"
    docker system df 2>/dev/null || skipped "docker not reachable"
  else
    run_cmd "docker system prune -f"
  fi

  # ── 2. Remove ALL unused images (not just dangling) ───────────────────────
  UNUSED_IMAGES=$(docker images -f "dangling=false" --format "{{.Repository}}:{{.Tag}} {{.Size}}" 2>/dev/null | grep -v "^<none>" || true)
  if [[ -n "$UNUSED_IMAGES" ]]; then
    info "All local images (showing for reference):"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" 2>/dev/null || true
    echo
    read -rp "  Remove ALL unused images (not running in any container)? [y/N] " yn
    if [[ "${yn,,}" == "y" ]]; then
      run_cmd "docker image prune -a -f"
    else
      skipped "unused images kept"
    fi
  fi

  # ── 3. Volumes ────────────────────────────────────────────────────────────
  info "Unused docker volumes:"
  docker volume ls -f dangling=true 2>/dev/null || true
  read -rp "  Remove dangling volumes? [y/N] " yn
  if [[ "${yn,,}" == "y" ]]; then
    run_cmd "docker volume prune -f"
  else
    skipped "volumes kept"
  fi

  # ── 4. Build cache ────────────────────────────────────────────────────────
  info "BuildKit cache:"
  docker buildx du 2>/dev/null || true
  read -rp "  Clear all build cache? [y/N] " yn
  if [[ "${yn,,}" == "y" ]]; then
    run_cmd "docker buildx prune -a -f"
  else
    skipped "build cache kept"
  fi

  # ── 5. Colima VM disk image ───────────────────────────────────────────────
  COLIMA_DISK="$HOME/.colima/_lima"
  info "Colima VM data dir: $(disk_usage "$COLIMA_DISK")"
  warn "To reclaim VM disk space you must stop colima, resize, or delete the VM."
  warn "  colima stop && colima delete   # nuclear option — removes ALL containers/images"
  warn "  colima start --disk 60         # re-create with a 60 GB disk (default is 100 GB)"

  # ── 6. Colima profiles ────────────────────────────────────────────────────
  info "Colima profiles present:"
  ls "$HOME/.colima/" 2>/dev/null || true

  # ── 7. Docker config / contexts ──────────────────────────────────────────
  DOCKER_CONFIG="$HOME/.docker"
  info "Docker config dir: $(disk_usage "$DOCKER_CONFIG")"

  echo -e "\n  ${GREEN}Docker/Colima cleanup done.${RESET}"
}

# =============================================================================
# RUST
# =============================================================================
cleanup_rust() {
  header "Rust Dev Artifacts"

  # ── 1. cargo registry cache ───────────────────────────────────────────────
  CARGO_REGISTRY="$HOME/.cargo/registry"
  info "cargo registry (downloaded crates): $(disk_usage "$CARGO_REGISTRY")"

  # Show breakdown
  if [[ -d "$CARGO_REGISTRY/cache" ]]; then
    info "  cache  (compressed .crate files): $(disk_usage "$CARGO_REGISTRY/cache")"
  fi
  if [[ -d "$CARGO_REGISTRY/src" ]]; then
    info "  src    (extracted source):        $(disk_usage "$CARGO_REGISTRY/src")"
  fi

  read -rp "  Clear extracted src (keeps compressed cache, re-extractable)? [y/N] " yn
  if [[ "${yn,,}" == "y" ]]; then
    run_cmd "rm -rf '$CARGO_REGISTRY/src'"
  fi

  read -rp "  Clear full registry cache (will re-download crates as needed)? [y/N] " yn
  if [[ "${yn,,}" == "y" ]]; then
    run_cmd "rm -rf '$CARGO_REGISTRY'"
  fi

  # ── 2. cargo git cache ────────────────────────────────────────────────────
  CARGO_GIT="$HOME/.cargo/git"
  if [[ -d "$CARGO_GIT" ]]; then
    info "cargo git checkouts: $(disk_usage "$CARGO_GIT")"
    read -rp "  Clear cargo git cache? [y/N] " yn
    if [[ "${yn,,}" == "y" ]]; then
      run_cmd "rm -rf '$CARGO_GIT'"
    fi
  fi

  # ── 3. cargo-cache (if installed) ────────────────────────────────────────
  if command -v cargo-cache &>/dev/null; then
    info "cargo-cache report:"
    cargo-cache --info 2>/dev/null || true
    read -rp "  Run cargo cache --autoclean? [y/N] " yn
    if [[ "${yn,,}" == "y" ]]; then
      run_cmd "cargo cache --autoclean"
    fi
  else
    info "cargo-cache not installed. Install for smarter cache pruning:"
    info "  cargo install cargo-cache"
  fi

  # ── 4. Project target/ directories ───────────────────────────────────────
  header "Rust project target/ directories"

  # Search common dev locations — edit SEARCH_DIRS to match your setup
  SEARCH_DIRS=(
    "$HOME/code"
    "$HOME/dev"
    "$HOME/projects"
    "$HOME/src"
    "$HOME/work"
    "$HOME/Developer"
  )

  TARGET_DIRS=()
  for dir in "${SEARCH_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      while IFS= read -r -d '' t; do
        TARGET_DIRS+=("$t")
      done < <(find "$dir" -maxdepth 6 -type d -name "target" \
                  -not -path "*/\.*" \
                  -not -path "*/node_modules/*" \
                  -print0 2>/dev/null)
    fi
  done

  if [[ ${#TARGET_DIRS[@]} -eq 0 ]]; then
    warn "No target/ directories found under: ${SEARCH_DIRS[*]}"
    warn "Edit SEARCH_DIRS in this script to match your project paths."
  else
    info "Found ${#TARGET_DIRS[@]} target/ director(ies):"
    TOTAL_TARGET=0
    for t in "${TARGET_DIRS[@]}"; do
      SIZE=$(du -sk "$t" 2>/dev/null | awk '{print $1}')
      TOTAL_TARGET=$((TOTAL_TARGET + SIZE))
      printf "    %-80s %s\n" "$t" "$(du -sh "$t" 2>/dev/null | awk '{print $1}')"
    done
    echo
    info "Total target/ size: $(echo "$TOTAL_TARGET" | awk '{printf "%.1f GB\n", $1/1024/1024}')"

    echo
    echo "  Options:"
    echo "    1) cargo clean each project (safe — preserves Cargo.lock)"
    echo "    2) rm -rf each target/ directly (faster)"
    echo "    3) skip"
    read -rp "  Choice [1/2/3]: " choice

    case $choice in
      1)
        for t in "${TARGET_DIRS[@]}"; do
          proj=$(dirname "$t")
          if [[ -f "$proj/Cargo.toml" ]]; then
            run_cmd "cargo clean --manifest-path '$proj/Cargo.toml'"
          else
            warn "No Cargo.toml adjacent to $t — skipping"
          fi
        done
        ;;
      2)
        for t in "${TARGET_DIRS[@]}"; do
          run_cmd "rm -rf '$t'"
        done
        ;;
      3) skipped "target/ directories kept" ;;
      *) skipped "invalid choice — keeping target/ directories" ;;
    esac
  fi

  # ── 5. rustup toolchains ─────────────────────────────────────────────────
  header "Rust toolchains (rustup)"
  if command -v rustup &>/dev/null; then
    info "Installed toolchains:"
    rustup toolchain list 2>/dev/null || true
    echo
    RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
    info "Total rustup size: $(disk_usage "$RUSTUP_HOME")"
    info "To remove a toolchain:  rustup toolchain uninstall <name>"
    info "To remove old components only:  rustup self update && rustup update"
    run_cmd "rustup self update"
    run_cmd "rustup update"

    read -rp "  List and interactively remove unused toolchains? [y/N] " yn
    if [[ "${yn,,}" == "y" ]]; then
      CHAINS=()
      while IFS= read -r line; do
        CHAINS+=("$line")
      done < <(rustup toolchain list | grep -v "(default)")

      if [[ ${#CHAINS[@]} -eq 0 ]]; then
        info "Only the default toolchain is installed — nothing to remove."
      else
        for chain in "${CHAINS[@]}"; do
          read -rp "  Remove '$chain'? [y/N] " yn2
          if [[ "${yn2,,}" == "y" ]]; then
            run_cmd "rustup toolchain uninstall '$chain'"
          fi
        done
      fi
    fi
  else
    skipped "rustup not found"
  fi

  # ── 6. cargo-installed binaries ───────────────────────────────────────────
  CARGO_BIN="$HOME/.cargo/bin"
  if [[ -d "$CARGO_BIN" ]]; then
    info "Cargo-installed binaries: $(disk_usage "$CARGO_BIN")"
    info "Listing (review manually for unused tools):"
    ls "$CARGO_BIN" 2>/dev/null | column
  fi

  echo -e "\n  ${GREEN}Rust cleanup done.${RESET}"
}

# =============================================================================
# Dispatch
# =============================================================================
case "$SECTION" in
  nix)    cleanup_nix    ;;
  docker) cleanup_docker ;;
  rust)   cleanup_rust   ;;
  all)
    cleanup_nix
    cleanup_docker
    cleanup_rust
    ;;
esac

# =============================================================================
# Summary
# =============================================================================
header "Summary"
warn "Computing sizes with du — may take 1-2 min on large dirs..."
echo

# /nix/store: use df (instant); du would stat every file in a 400 GB store
nix_used=$(df -h /nix/store 2>/dev/null | awk 'NR==2{print $3}')
nix_total=$(df -h /nix/store 2>/dev/null | awk 'NR==2{print $2}')
echo -e "  ${BOLD}/nix/store:${RESET}          ${nix_used} used / ${nix_total} total (df)"

# For the rest, du is fine — much smaller than the nix store
for entry in \
  "~/.cargo|$HOME/.cargo" \
  "~/.rustup|${RUSTUP_HOME:-$HOME/.rustup}" \
  "~/.colima|$HOME/.colima" \
  "~/.cache/nix|$HOME/.cache/nix" \
  "~/.cache/direnv|$HOME/.cache/direnv"
do
  label="${entry%%|*}"
  path="${entry##*|}"
  printf "  %-28s %s\n" "${BOLD}${label}:${RESET}" "$(disk_usage "$path")"
done

if $DRY_RUN; then
  echo
  warn "This was a DRY RUN. Re-run with --run to apply changes:"
  echo -e "  ${BOLD}./cleanup-dev-disk.sh --run${RESET}"
  echo -e "  ${BOLD}./cleanup-dev-disk.sh --run --section nix${RESET}"
  echo -e "  ${BOLD}./cleanup-dev-disk.sh --run --section docker${RESET}"
  echo -e "  ${BOLD}./cleanup-dev-disk.sh --run --section rust${RESET}"
fi

echo
