# Dual Boot Plan: Windows 11 (Disk 1) + NixOS (Disk 0) with Secure Boot

## Summary
- Windows 11 on Disk 1, NixOS on Disk 0.
- Shared EFI System Partition (ESP) on Disk 1 mounted at /boot in NixOS.
- NixOS default boot with fast menu timeout (0 or 1 second).
- One-time reboot into Windows from NixOS using systemd-boot entry.
- Btrfs on LUKS full-disk encryption for Disk 0.
- Flakes with host zeus.
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
`
lsblk -o NAME,SIZE,MODEL,TYPE,FSTYPE
`
Set:
- DISK0=/dev/... (NixOS disk)
- ESP_UUID=XXXX-XXXX (EFI partition on Disk 1)

### Partition Disk 0 and set up LUKS + Btrfs
`
sgdisk --zap-all 
sgdisk -n 1:0:0 -t 1:8309 -c 1: nixos-crypt 

cryptsetup luksFormat p1
cryptsetup open p1 cryptroot

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
mount /dev/disk/by-uuid/ /mnt/boot
`

### Generate hardware config
`
nixos-generate-config --root /mnt
`

### Install with flakes
If you can clone your repo:
`
git clone <your repo url> /mnt/etc/nixos
`
Or if you use your custom installer ISO, /mnt/etc/nixos already exists.

Then:
`
nixos-install --flake /mnt/etc/nixos#zeus
reboot
`

## Flake changes for Lanzaboote
Edit lake.nix:
- Add lanzaboote input.
- Include lanzaboote.nixosModules.lanzaboote in the mkZeus modules list.

Example snippet (merge with existing):
`
inputs = {
  nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
  lanzaboote = {
    url = github:nix-community/lanzaboote/v0.3.0;
    inputs.nixpkgs.follows = nixpkgs;
  };
  ...
};

modules = [
  ...
  lanzaboote.nixosModules.lanzaboote
] ++ extraModules;
`

## Initial boot (systemd-boot)
Before enabling Lanzaboote, ensure systemd-boot is on:
`
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
boot.loader.timeout = 0;
`

## Enable Lanzaboote (after first boot)
`
environment.systemPackages = [ pkgs.sbctl ];

boot.loader.systemd-boot.enable = lib.mkForce false;
boot.lanzaboote = {
  enable = true;
  pkiBundle = /etc/secureboot;
};
`

Rebuild:
`
sudo nixos-rebuild switch --flake /etc/nixos#zeus
`

## Enroll Secure Boot keys
`
sudo sbctl create-keys
sudo sbctl verify
`

Put firmware into Secure Boot setup mode, then:
`
sudo sbctl enroll-keys --microsoft
reboot
`

Verify:
`
bootctl status
`

## Set NixOS default and one-time Windows boot
`
bootctl list
sudo bootctl set-default <nixos-id>
sudo bootctl set-oneshot <windows-id>
sudo systemctl reboot
`

Alternative one-liner:
`
sudo systemctl reboot --boot-loader-entry=<windows-id>
`

## Hibernation (not configured)
This setup uses zram swap and no hibernation. If you want hibernation later, add a dedicated swap partition or Btrfs swapfile and set oot.resumeDevice and oot.resumeOffset.
