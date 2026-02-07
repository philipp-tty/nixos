# Dual boot plan (zeus): Windows 11 + NixOS + Secure Boot

This is a zeus-specific install plan. Commands here are destructive; read the whole file and adapt device names/UUIDs before running anything.
Last reviewed: 2026-02-06.

## Summary
- Windows 11 on Disk 1, NixOS on Disk 0.
- Shared EFI System Partition (ESP) on Disk 1 mounted at `/boot` in NixOS.
- NixOS default boot with short menu timeout (0-1 seconds).
- One-time reboot into Windows from NixOS using systemd-boot entry.
- Btrfs on LUKS full-disk encryption for Disk 0.
- Flakes with host `zeus`.
- Hibernation not configured (zram swap only).

## Firmware prerequisites
1. UEFI only (CSM/Legacy off).
2. Secure Boot enabled, but allow Setup Mode for key enrollment later.
3. SATA/NVMe controller in AHCI mode (if applicable).

## Windows installation (Disk 1)
1. Install Windows 11 first.
2. In Custom partitioning, ensure an ESP of at least 512 MiB on Disk 1.
3. Finish install and reboot once to confirm it boots.
4. Optional: Disable Windows Fast Startup after install to avoid hybrid shutdown issues.

## NixOS installation (Disk 0)
### Identify disks and ESP
```sh
lsblk -o NAME,SIZE,MODEL,TYPE,FSTYPE
```
Set:
- `DISK0=/dev/...` (NixOS disk)
- `CRYPT_PART=/dev/...` (the NixOS partition on Disk 0; adjust for your device naming)
- `ESP_UUID=XXXX-XXXX` (EFI partition UUID on Disk 1)

### Partition Disk 0 and set up LUKS + Btrfs
```sh
# Danger: destructive. Double-check DISK0/CRYPT_PART before running.
sgdisk --zap-all "$DISK0"
sgdisk -n 1:0:0 -t 1:8309 -c 1:nixos-crypt "$DISK0"

cryptsetup luksFormat "$CRYPT_PART"
cryptsetup open "$CRYPT_PART" cryptroot

mkfs.btrfs -L nixos /dev/mapper/cryptroot

mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
umount /mnt

mount -o subvol=@,compress=zstd,noatime,ssd,space_cache=v2 /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{home,nix,boot}
mount -o subvol=@home,compress=zstd,noatime,ssd,space_cache=v2 /dev/mapper/cryptroot /mnt/home
mount -o subvol=@nix,compress=zstd,noatime,ssd,space_cache=v2 /dev/mapper/cryptroot /mnt/nix

# Mount the Windows ESP as /boot
mount "/dev/disk/by-uuid/${ESP_UUID}" /mnt/boot
```

### Generate hardware config
```sh
nixos-generate-config --root /mnt
```

### Install with flakes
After `nixos-generate-config --root /mnt`, `/mnt/etc/nixos` is non-empty. Either use the bootstrap flow from `docs/INSTALL.md`, or move it aside before cloning:

```sh
mv /mnt/etc/nixos /mnt/etc/nixos.generated
nix-shell -p git --run "git clone <your repo url> /mnt/etc/nixos"
cp /mnt/etc/nixos.generated/hardware-configuration.nix /mnt/etc/nixos/hosts/zeus/hardware-configuration.nix
nixos-install --flake /mnt/etc/nixos#zeus
reboot
```

## Flake changes for Lanzaboote
Edit flake.nix:
- Add lanzaboote input.
- Include lanzaboote.nixosModules.lanzaboote in the mkZeus modules list.

Example snippet (merge with existing):
```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  lanzaboote = {
    url = "github:nix-community/lanzaboote/v0.3.0";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  ...
};

modules = [
  ...
  lanzaboote.nixosModules.lanzaboote
] ++ extraModules;
```

## Initial boot (systemd-boot)
Before enabling Lanzaboote, ensure systemd-boot is on:
```nix
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
boot.loader.timeout = 0;
```

## Enable Lanzaboote (after first boot)
```nix
environment.systemPackages = [ pkgs.sbctl ];

boot.loader.systemd-boot.enable = lib.mkForce false;
boot.lanzaboote = {
  enable = true;
  pkiBundle = /etc/secureboot;
};
```

Rebuild:
```sh
sudo nixos-rebuild switch --flake /etc/nixos#zeus
```

## Enroll Secure Boot keys
```sh
sudo sbctl create-keys
sudo sbctl verify
```

Put firmware into Secure Boot setup mode, then:
```sh
sudo sbctl enroll-keys --microsoft
reboot
```

Verify:
```sh
bootctl status
```

## Set NixOS default and one-time Windows boot

### Using the reboot-to-windows script (recommended)

The easiest way to reboot into Windows is using the provided script:

```sh
reboot-to-windows
```

This script automatically:
- Detects the Windows boot entry
- Sets it as a one-time boot target
- Reboots the system

Additional options:
```sh
reboot-to-windows --list      # List all available boot entries
reboot-to-windows --dry-run   # Show what would be done without rebooting
reboot-to-windows --help      # Show help message
```

### Manual method (advanced)

If you need more control, you can use bootctl directly:

```sh
bootctl list
sudo bootctl set-default <nixos-id>
sudo bootctl set-oneshot <windows-id>
sudo systemctl reboot
```

Alternative one-liner:
```sh
sudo systemctl reboot --boot-loader-entry=<windows-id>
```

## Hibernation (not configured)
This setup uses zram swap and no hibernation. If you want hibernation later, add a dedicated swap partition or Btrfs swapfile and set `boot.resumeDevice` and `boot.resumeOffset`.
