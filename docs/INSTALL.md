# Install notes (manual partitioning)

Goal: keep `/home` on its own partition so you can reinstall NixOS without losing user data.

## Suggested layout (UEFI + GPT)

- EFI System Partition: 512 MiB, FAT32, mount at `/boot`
- Root partition: 60-120 GiB, ext4, mount at `/`
- Home partition: rest of disk, ext4, mount at `/home`
- Optional swap: 8-32 GiB (or use a swap file later)

## High-level steps (installer shell)

1. Create the partitions (e.g. `gdisk`, `parted`, `cfdisk`).
2. Format them:

```sh
mkfs.fat -F32 /dev/nvme0n1p1
mkfs.ext4 -L nixos /dev/nvme0n1p2
mkfs.ext4 -L home /dev/nvme0n1p3
```

3. Mount them:

```sh
mount /dev/nvme0n1p2 /mnt
mkdir -p /mnt/boot /mnt/home
mount /dev/nvme0n1p1 /mnt/boot
mount /dev/nvme0n1p3 /mnt/home
```

4. Generate configs:

```sh
nixos-generate-config --root /mnt
```

5. Copy `/mnt/etc/nixos/hardware-configuration.nix` into this repo at `hosts/zeus/hardware-configuration.nix`.
6. Install NixOS, then rebuild using the flake.

## Bootstrap script (installer or first boot)

The script `scripts/bootstrap.sh` will:

- clone/update the repo
- copy `hardware-configuration.nix` into `hosts/zeus/`
- run `nixos-install` (installer) or `nixos-rebuild` (first boot)

### Installer usage

After mounting `/mnt` and running `nixos-generate-config`:

```sh
nix-shell -p git --run "git clone https://github.com/philipp-tty/nixos /mnt/etc/nixos"
/mnt/etc/nixos/scripts/bootstrap.sh
```

### Direct run (no clone)

Installer (runs `nixos-install`):

```sh
nix-shell -p curl --run "curl -fsSL https://raw.githubusercontent.com/philipp-tty/nixos/main/scripts/bootstrap.sh | bash"
```

First boot (runs `nixos-rebuild`):

```sh
nix-shell -p curl --run "curl -fsSL https://raw.githubusercontent.com/philipp-tty/nixos/main/scripts/bootstrap.sh | bash"
```

To target a different host, set `HOST=your-hostname` before the command.

### First boot usage

```sh
nix-shell -p git --run "git clone https://github.com/philipp-tty/nixos ~/nixos"
~/nixos/scripts/bootstrap.sh
```

To skip the install/rebuild step, set `SKIP_INSTALL=1` or `SKIP_REBUILD=1`.

## First boot (after install)

1. Log in and make sure networking works (wired is easiest).
2. Open a terminal and get `git` if you don't have it yet:

```sh
nix-shell -p git
```

3. Clone the repo and enter it:

```sh
git clone https://github.com/philipp-tty/nixos
cd nixos
```

4. Copy the generated hardware config into the repo (use `sudo` if you get a permission error):

```sh
cp /etc/nixos/hardware-configuration.nix hosts/zeus/hardware-configuration.nix
```

5. Apply your flake (temporarily enable flakes if needed):

```sh
sudo NIX_CONFIG="experimental-features = nix-command flakes" nixos-rebuild switch --flake .#zeus
```

6. Reboot and confirm GNOME + your packages are present.

## Keeping your SSH files

- If `/home` is on its own partition, `~/.ssh` stays intact across reinstalls.
- Create the same username during reinstall (or set `users.users.<name>.uid` to match) so ownership stays correct.
- As a safety net, back up `~/.ssh` to external storage before reinstalling.
