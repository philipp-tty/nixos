# NixOS machines

This repo tracks my NixOS machines and setups.

## Layout

- `flake.nix` -> system entrypoints (one per host)
- `hosts/` -> per-machine configs
- `docs/` -> install notes and checklists

## Quick start (after install)

1. Copy the generated hardware config into `hosts/zeus/hardware-configuration.nix`.
2. Edit `hosts/zeus/configuration.nix` to set your username, timezone, and any extras.
3. Apply the config:

```sh
sudo nixos-rebuild switch --flake .#zeus
```

For a guided install/first-boot flow, use `scripts/bootstrap.sh` (see `docs/INSTALL.md`).

## Notes

- Keep secrets out of this repo (SSH keys, tokens, etc.).
- Use the same Linux username when reinstalling if you want to keep your existing `/home` data.
- See `docs/INSTALL.md` for the /home partition plan and first-install checklist.
