{
  config,
  lib,
  pkgs,
  pkgsUnstable,
  ...
}: let
  enabled = config.local.emulators.enable;
in {
  options.local.emulators.enable = lib.mkEnableOption "Emulator packages";

  config = lib.mkIf enabled {
    environment.systemPackages = [
      # Nintendo DS emulator (user requested "lemonds").
      pkgsUnstable.melonds
      pkgs.universal-pokemon-randomizer-zx
    ];
  };
}
