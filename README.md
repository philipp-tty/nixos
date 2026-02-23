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

# update pinned inputs (updates flake.lock)
nix flake update

# apply config (switch now)
sudo nixos-rebuild switch --flake .#zeus

# try config without switching permanently
sudo nixos-rebuild test --flake .#zeus

# eval + flake checks (useful in CI)
nix flake check

# reboot into Windows (dual-boot)
reboot-to-windows
```

## Update All Packages to the Latest Version

To update everything this flake tracks to the newest available revisions:

```sh
cd ~/nixos

# update all flake inputs to latest commits on their configured branches
nix flake update

# optional: review exactly what changed
git diff -- flake.lock

# apply the updated package set
sudo nixos-rebuild switch --flake .#zeus
```

Note: this gets the latest versions on the branches set in `flake.nix` (for example `nixos-25.11` and `release-25.11`). To move to a newer release line, change those input URLs first, then run `nix flake update`.

## Switching KDE <-> GNOME

Desktop environment is selected per-host via `local.desktop`.

Edit `hosts/zeus/desktop.nix`:

- KDE Plasma: `local.desktop = "kde";`
- GNOME: `local.desktop = "gnome";`
- No desktop: `local.desktop = "none";`

Then apply:

```sh
sudo nixos-rebuild switch --flake .#zeus
```

Changing the display manager (SDDM <-> GDM) is safest with a reboot.

## Customizing

This is a personal config; if you fork it, you almost certainly want to change:
- `hosts/zeus/base.nix`: hostname, timezone, packages, system user(s)
- `hosts/zeus/home.nix`: Home Manager settings (`home.username`, GNOME dconf, etc.)
- `flake.nix`: the Home Manager user binding (`home-manager.users.<name> = ...`)

## Disk Usage (Automatic Cleanup)

This config enables automatic Nix garbage collection and limits the number of boot entries:

- `nix.gc.*` in `hosts/zeus/base.nix`
- `boot.loader.systemd-boot.configurationLimit` in `hosts/zeus/base.nix`

## Docs

- `docs/INSTALL.md`: install + bootstrap details
- `docs/SECRETS.md`: sops-nix notes and "don't commit secrets"
- `docs/dualboot-windows11-nixos-zeus.md`: zeus-specific dual boot plan
