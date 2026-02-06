{ ... }:

{
  # Minimal placeholder so the flake evaluates on CI machines.
  # `scripts/bootstrap.sh` overwrites this with your real generated config.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };
}
