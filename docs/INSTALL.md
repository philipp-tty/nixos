# Install / Bootstrap

This repo is a Nix flake. You apply a host config with:

```sh
sudo nixos-rebuild switch --flake /path/to/repo#<host>
```

Currently defined hosts live in `flake.nix` (`zeus`, `zeus-ci`). You can list them with:

```sh
nix flake show
```

Before installing, skim the host files you are about to deploy:
- `hosts/zeus/base.nix` (hostname, timezone, users, packages)
- `hosts/zeus/home.nix` (Home Manager user + GNOME settings)

## Fast Path (Recommended): `scripts/bootstrap.sh`

The bootstrap script is meant for:
- the NixOS installer (it runs `nixos-install`)
- an installed machine (it runs `nixos-rebuild switch`)

What it does:
- clone or pull the repo
- copy `hardware-configuration.nix` into `hosts/$HOST/hardware-configuration.nix` (when present)
- run the install or rebuild with flakes enabled via `NIX_CONFIG`

Environment variables:
- `HOST` (default: `zeus`)
- `REPO_URL` (default: `https://github.com/philipp-tty/nixos`)
- `TARGET_DIR` (only on installed systems when running as a user; default: `~/nixos`)
- `SKIP_INSTALL=1` / `SKIP_REBUILD=1` (sync files only)

### Fresh install (from the NixOS ISO)

1. Partition + mount your filesystems under `/mnt`.
2. Generate the initial hardware config:

```sh
nixos-generate-config --root /mnt
```

3. Clone the repo somewhere and run bootstrap (it will install the repo into `/mnt/etc/nixos`):

```sh
nix-shell -p git --run "git clone https://github.com/philipp-tty/nixos /tmp/nixos"
HOST=zeus /tmp/nixos/scripts/bootstrap.sh
reboot
```

### First boot / existing install

```sh
nix-shell -p git --run "git clone https://github.com/philipp-tty/nixos ~/nixos"
cd ~/nixos
HOST=zeus ./scripts/bootstrap.sh
```

## Manual Install (No Bootstrap)

### Fresh install (from the NixOS ISO)

After mounting `/mnt` and running `nixos-generate-config --root /mnt`:

```sh
mv /mnt/etc/nixos /mnt/etc/nixos.generated
nix-shell -p git --run "git clone https://github.com/philipp-tty/nixos /mnt/etc/nixos"
cp /mnt/etc/nixos.generated/hardware-configuration.nix /mnt/etc/nixos/hosts/zeus/hardware-configuration.nix
nixos-install --flake /mnt/etc/nixos#zeus
reboot
```

### Apply on an installed system

```sh
nix-shell -p git --run "git clone https://github.com/philipp-tty/nixos ~/nixos"
cd ~/nixos
cp /etc/nixos/hardware-configuration.nix hosts/zeus/hardware-configuration.nix
sudo nixos-rebuild switch --flake .#zeus
```

If flakes aren't enabled yet, prefix with:

```sh
sudo env NIX_CONFIG="experimental-features = nix-command flakes" nixos-rebuild switch --flake .#zeus
```

## Suggested Partitioning (Optional)

If you want to be able to reinstall without wiping your home directory, keep `/home` on a separate partition.

Suggested UEFI + GPT layout:
- EFI System Partition: 512 MiB, FAT32, mounted at `/boot`
- Root partition: 60-120 GiB, ext4, mounted at `/`
- Home partition: rest of disk, ext4, mounted at `/home`
- Optional swap: 8-32 GiB (or use a swap file/zram later)

Example (adjust device names):

```sh
mkfs.fat -F32 /dev/nvme0n1p1
mkfs.ext4 -L nixos /dev/nvme0n1p2
mkfs.ext4 -L home /dev/nvme0n1p3

mount /dev/nvme0n1p2 /mnt
mkdir -p /mnt/boot /mnt/home
mount /dev/nvme0n1p1 /mnt/boot
mount /dev/nvme0n1p3 /mnt/home
```

Keeping SSH across reinstalls:
- if `/home` is separate, `~/.ssh` survives reinstalls automatically
- use the same Linux username (or match the UID) so file ownership stays correct
