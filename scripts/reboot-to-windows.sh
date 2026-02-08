#!/usr/bin/env bash
# Reboot into Windows from NixOS (dual-boot systems with systemd-boot)

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Reboot into Windows on a dual-boot NixOS system.

OPTIONS:
  -l, --list      List available boot entries and exit
  -h, --help      Show this help message
  -n, --dry-run   Show what would be done without actually rebooting

EXAMPLES:
  $(basename "$0")              # Reboot into Windows
  $(basename "$0") --list       # List available boot entries
  $(basename "$0") --dry-run    # Show the command without executing

This script requires systemd-boot and root privileges.
EOF
}

log() {
  echo "[reboot-to-windows] $*" >&2
}

error() {
  echo "[reboot-to-windows] ERROR: $*" >&2
  exit 1
}

# Parse command line arguments
list_only=false
dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -l|--list)
      list_only=true
      shift
      ;;
    -n|--dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      error "Unknown option: $1. Use --help for usage information."
      ;;
  esac
done

# Check if bootctl is available
if ! command -v bootctl >/dev/null 2>&1; then
  error "bootctl command not found. This script requires systemd-boot."
fi

# List boot entries
log "Fetching boot entries..."
if ! boot_entries=$(bootctl list 2>/dev/null); then
  error "Failed to list boot entries. Make sure systemd-boot is properly configured."
fi

if [ "$list_only" = true ]; then
  echo "$boot_entries"
  exit 0
fi

# Find Windows boot entry
# Look for common Windows boot entry patterns
# Strategy: Parse entry blocks (separated by empty lines) and find the one with "Windows" in the title
windows_id=""
current_id=""
current_title=""

while IFS= read -r line || [ -n "$line" ]; do
  # Empty line marks the end of an entry block
  if [[ "$line" =~ ^[[:space:]]*$ ]] || [ -z "$line" ]; then
    # Check if the current block is a Windows entry
    if [[ "$current_title" =~ [Ww]indows ]] && [ -n "$current_id" ]; then
      windows_id="$current_id"
      break
    fi
    # Reset for next block
    current_id=""
    current_title=""
    continue
  fi
  
  # Extract title
  if [[ "$line" =~ ^[[:space:]]*title:[[:space:]]*(.+[^[:space:]])[[:space:]]*$ ]]; then
    current_title="${BASH_REMATCH[1]}"
  fi
  
  # Extract id
  if [[ "$line" =~ ^[[:space:]]*id:[[:space:]]*(.+[^[:space:]])[[:space:]]*$ ]]; then
    current_id="${BASH_REMATCH[1]}"
  fi
done <<< "$boot_entries"

# Check the last block if we reached EOF without an empty line
if [[ "$current_title" =~ [Ww]indows ]] && [ -n "$current_id" ]; then
  windows_id="$current_id"
fi

if [ -z "$windows_id" ]; then
  error "Could not find Windows boot entry. Use --list to see available entries."
fi

log "Found Windows boot entry: $windows_id"

if [ "$dry_run" = true ]; then
  log "Dry-run mode: would execute: sudo systemctl reboot --boot-loader-entry=\"$windows_id\""
  exit 0
fi

# Reboot into Windows
if [ "$(id -u)" -eq 0 ]; then
  log "Rebooting into Windows..."
  systemctl reboot --boot-loader-entry="$windows_id"
else
  log "Rebooting into Windows (requires sudo)..."
  sudo systemctl reboot --boot-loader-entry="$windows_id"
fi
