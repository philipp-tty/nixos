# NixOS machines (flake)

Personal NixOS flake for my machines.

Defined hosts:
- `zeus`: primary desktop config
- `zeus-ci`: CI-only build target (minimal "hardware" so GitHub Actions can build)

Repo layout:
- `flake.nix`: flake outputs (`nixosConfigurations.*`)
- `hosts/`: per-host NixOS + Home Manager modules
- `scripts/`: bootstrap helpers
- `docs/`: extra notes

## Install / Apply

### Apply on an existing machine

```sh
nix-shell -p git --run "git clone https://github.com/philipp-tty/nixos ~/nixos"
cd ~/nixos

# First time only (or after reinstall): refresh hardware config
cp /etc/nixos/hardware-configuration.nix hosts/zeus/hardware-configuration.nix

sudo nixos-rebuild switch --flake .#zeus
```

If flakes aren't enabled yet, run the rebuild with:

```sh
sudo env NIX_CONFIG="experimental-features = nix-command flakes" nixos-rebuild switch --flake .#zeus
```

### Fresh install from the NixOS ISO

After partitioning + mounting `/mnt`:

```sh
nixos-generate-config --root /mnt
nix-shell -p git --run "git clone https://github.com/philipp-tty/nixos /tmp/nixos"
HOST=zeus /tmp/nixos/scripts/bootstrap.sh
reboot
```

## Common Commands

```sh
# show available flake outputs
nix flake show

# apply config (switch now)
sudo nixos-rebuild switch --flake .#zeus

# try config without switching permanently
sudo nixos-rebuild test --flake .#zeus

# eval + flake checks (useful in CI)
nix flake check

# update pinned inputs (creates/updates flake.lock)
nix flake update
```

## Customizing

This is a personal config; if you fork it, you almost certainly want to change:
- `hosts/zeus/base.nix`: hostname, timezone, packages, system user(s)
- `hosts/zeus/home.nix`: Home Manager settings (`home.username`, GNOME dconf, etc.)
- `flake.nix`: the Home Manager user binding (`home-manager.users.<name> = ...`)

## Docs

- `docs/INSTALL.md`: install + bootstrap details
- `docs/SECRETS.md`: sops-nix notes and "don't commit secrets"
- `docs/dualboot-windows11-nixos-zeus.md`: zeus-specific dual boot plan
