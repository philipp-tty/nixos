#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/philipp-tty/nixos}"
HOST="${HOST:-zeus}"
NIX_EXPERIMENTAL="experimental-features = nix-command flakes"

is_installer=false
if command -v findmnt >/dev/null 2>&1; then
  if findmnt -rno TARGET /mnt >/dev/null 2>&1; then
    is_installer=true
  fi
elif [ -r /proc/mounts ]; then
  if grep -q " /mnt " /proc/mounts; then
    is_installer=true
  fi
fi

if $is_installer; then
  target_dir="/mnt/etc/nixos"
  hw_src="/mnt/etc/nixos/hardware-configuration.nix"
else
  if [ "$(id -u)" -eq 0 ]; then
    target_dir="/etc/nixos"
  else
    target_dir="${TARGET_DIR:-$HOME/nixos}"
  fi
  hw_src="/etc/nixos/hardware-configuration.nix"
fi

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
    echo "git not found and nix-shell not available. Install git first." >&2
    exit 1
  fi
  local cmd
  cmd="git"
  for arg in "$@"; do
    cmd+=" $(printf "%q" "$arg")"
  done
  nix-shell -p git --run "$cmd"
}

hw_tmp=""
if [ -f "$hw_src" ]; then
  hw_tmp="$(mktemp)"
  cp "$hw_src" "$hw_tmp"
fi

if [ -d "$target_dir/.git" ]; then
  gitx -C "$target_dir" pull --ff-only
else
  if [ -d "$target_dir" ] && [ "$(ls -A "$target_dir")" ]; then
    backup="${target_dir}.bak-$(date +%Y%m%d-%H%M%S)"
    run_as_root mv "$target_dir" "$backup"
  fi
  run_as_root mkdir -p "$(dirname "$target_dir")"
  gitx clone "$REPO_URL" "$target_dir"
fi

if [ -n "$hw_tmp" ]; then
  run_as_root mkdir -p "$target_dir/hosts/$HOST"
  run_as_root cp "$hw_tmp" "$target_dir/hosts/$HOST/hardware-configuration.nix"
fi

if $is_installer; then
  if [ "${SKIP_INSTALL:-0}" != "1" ]; then
    run_as_root env NIX_CONFIG="$NIX_EXPERIMENTAL" nixos-install --flake "$target_dir#$HOST"
  else
    echo "SKIP_INSTALL=1 set; skipping nixos-install."
  fi
else
  if [ "${SKIP_REBUILD:-0}" != "1" ]; then
    run_as_root env NIX_CONFIG="$NIX_EXPERIMENTAL" nixos-rebuild switch --flake "$target_dir#$HOST"
  else
    echo "SKIP_REBUILD=1 set; skipping nixos-rebuild."
  fi
fi
