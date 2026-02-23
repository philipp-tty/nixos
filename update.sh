#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./update.sh [HOST]

Update all flake inputs (flake.lock) and switch NixOS to the updated config.
HOST defaults to $HOST or the current short hostname.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

FLAKE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_HOST="${1:-${HOST:-$(hostname -s)}}"
NIX_CONFIG_SNIPPET="experimental-features = nix-command flakes"

if [[ -n "${NIX_CONFIG:-}" ]]; then
  NIX_CONFIG_SNIPPET+=$'\n'"$NIX_CONFIG"
fi

log() {
  printf '[update] %s\n' "$*"
}

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

if [[ ! -f "$FLAKE_DIR/flake.nix" ]]; then
  printf '[update] ERROR: %s does not contain flake.nix\n' "$FLAKE_DIR" >&2
  exit 1
fi

log "Updating flake inputs in $FLAKE_DIR (this updates flake.lock)"
env NIX_CONFIG="$NIX_CONFIG_SNIPPET" nix flake update --flake "$FLAKE_DIR"

log "Switching to $FLAKE_DIR#$TARGET_HOST"
run_as_root env NIX_CONFIG="$NIX_CONFIG_SNIPPET" nixos-rebuild switch --flake "$FLAKE_DIR#$TARGET_HOST"

log "Done."
