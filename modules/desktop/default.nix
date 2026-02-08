{lib, ...}: {
  imports = [
    ./common.nix
    ./kde.nix
    ./gnome.nix
  ];

  options.local.desktop = lib.mkOption {
    type = lib.types.enum ["none" "kde" "gnome"];
    default = "none";
    example = "kde";
    description = ''
      Which desktop environment to enable on this host.

      - `kde`: KDE Plasma 6 + SDDM
      - `gnome`: GNOME + GDM
      - `none`: no desktop environment
    '';
  };
}
