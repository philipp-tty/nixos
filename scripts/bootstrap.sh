#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/philipp-tty/nixos}"
HOST="${HOST:-zeus}"
NIX_CONFIG_SNIPPET="$(
  cat <<'EOF'
experimental-features = nix-command flakes
extra-substituters = https://nix-community.cachix.org
extra-trusted-public-keys = nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
EOF
)"

log() { printf '[bootstrap] %s\n' "$*"; }

# -- Cleanup temp files on exit ------------------------------------------------
hw_tmp=""
cleanup() {
  if [ -n "$hw_tmp" ] && [ -f "$hw_tmp" ]; then
    rm -f "$hw_tmp"
  fi
}
trap cleanup EXIT

# -- Detect installer vs. installed system ------------------------------------
is_installer=false
if command -v findmnt >/dev/null 2>&1; then
  if findmnt -rno TARGET /mnt >/dev/null 2>&1; then
    is_installer=true
  fi
elif [ -r /proc/mounts ]; then
  if awk '$2 == "/mnt" { found=1; exit } END { exit !found }' /proc/mounts; then
    is_installer=true
  fi
fi

if $is_installer; then
  target_dir="/mnt/etc/nixos"
  hw_src="/mnt/etc/nixos/hardware-configuration.nix"
  log "Installer mode detected (filesystem mounted on /mnt)"
else
  if [ "$(id -u)" -eq 0 ]; then
    target_dir="/etc/nixos"
  else
    target_dir="${TARGET_DIR:-$HOME/nixos}"
  fi
  hw_src="/etc/nixos/hardware-configuration.nix"
  log "Running on an installed system"
fi
log "HOST=$HOST  target_dir=$target_dir"

# -- Helpers -------------------------------------------------------------------
run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

gitx() {
  if command -v git >/dev/null 2>&1; then
    git "$@"
    return
  fi
  if ! command -v nix-shell >/dev/null 2>&1; then
    log "ERROR: git command not found and nix-shell not available. Install git first." >&2
    exit 1
  fi
  local cmd
  cmd="git"
  for arg in "$@"; do
    cmd+=" $(printf "%q" "$arg")"
  done
  nix-shell -p git --run "$cmd"
}

run_nix_command() {
  # `sudo command -v ...` is unreliable because `command` is a shell builtin.
  # Check tool availability in the same root context we will run the nix command in.
  if run_as_root git --version >/dev/null 2>&1; then
    run_as_root env NIX_CONFIG="$NIX_CONFIG_SNIPPET" "$@"
    return
  fi
  if ! run_as_root nix-shell --version >/dev/null 2>&1; then
    log "ERROR: git command not available for root and nix-shell not available. Install git or make nix-shell available." >&2
    exit 1
  fi
  local cmd=""
  for arg in "$@"; do
    cmd+=" $(printf "%q" "$arg")"
  done
  run_as_root env NIX_CONFIG="$NIX_CONFIG_SNIPPET" nix-shell -p git --run "${cmd# }"
}

# -- Save hardware-configuration.nix before touching the target dir -----------
if [ -f "$hw_src" ]; then
  hw_tmp="$(mktemp)"
  cp -- "$hw_src" "$hw_tmp"
  log "Saved $hw_src to temporary file"
fi

# -- Clone or update the repo --------------------------------------------------
if [ -d "$target_dir/.git" ]; then
  log "Updating existing repo in $target_dir"
  gitx -C "$target_dir" pull --ff-only
else
  if [ -d "$target_dir" ] && [ -n "$(ls -A "$target_dir")" ]; then
    backup="${target_dir}.bak-$(date +%Y%m%d-%H%M%S)"
    log "Backing up existing $target_dir to $backup"
    run_as_root mv -- "$target_dir" "$backup"
  fi
  run_as_root mkdir -p -- "$(dirname "$target_dir")"
  log "Cloning $REPO_URL into $target_dir"
  gitx clone "$REPO_URL" "$target_dir"
fi

# -- Restore hardware-configuration.nix into the host directory ----------------
if [ -n "$hw_tmp" ]; then
  run_as_root mkdir -p -- "$target_dir/hosts/$HOST"
  run_as_root cp -- "$hw_tmp" "$target_dir/hosts/$HOST/hardware-configuration.nix"
  log "Restored hardware-configuration.nix into hosts/$HOST/"
  rm -f "$hw_tmp"
  hw_tmp=""
fi

# -- Install / Rebuild ---------------------------------------------------------
if $is_installer; then
  if [ "${SKIP_INSTALL:-0}" != "1" ]; then
    log "Running nixos-install --flake $target_dir#$HOST"
    run_nix_command nixos-install --flake "$target_dir#$HOST"
  else
    log "SKIP_INSTALL=1 set; skipping nixos-install."
  fi
else
  if [ "${SKIP_REBUILD:-0}" != "1" ]; then
    log "Running nixos-rebuild switch --flake $target_dir#$HOST"
    run_nix_command nixos-rebuild switch --flake "$target_dir#$HOST"
  else
    log "SKIP_REBUILD=1 set; skipping nixos-rebuild."
  fi
fi

log "Done."
