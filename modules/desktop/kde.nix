{
  lib,
  config,
  options,
  ...
}: let
  enabled = config.local.desktop == "kde";

  hasSddmNew = lib.hasAttrByPath ["services" "displayManager" "sddm" "enable"] options;
  hasSddmOld = lib.hasAttrByPath ["services" "xserver" "displayManager" "sddm" "enable"] options;

  hasPlasmaNew = lib.hasAttrByPath ["services" "desktopManager" "plasma6" "enable"] options;
  hasPlasmaOld = lib.hasAttrByPath ["services" "xserver" "desktopManager" "plasma6" "enable"] options;

  hasGdmNew = lib.hasAttrByPath ["services" "displayManager" "gdm" "enable"] options;
  hasGdmOld = lib.hasAttrByPath ["services" "xserver" "displayManager" "gdm" "enable"] options;
in {
  config = lib.mkIf enabled (lib.mkMerge [
    {
      assertions = [
        {
          assertion = hasSddmNew || hasSddmOld;
          message = "KDE selected (local.desktop = \"kde\"), but SDDM option path not found in this nixpkgs.";
        }
        {
          assertion = hasPlasmaNew || hasPlasmaOld;
          message = "KDE selected (local.desktop = \"kde\"), but Plasma 6 option path not found in this nixpkgs.";
        }
      ];
    }

    # KDE doesn't install its own SSH agent; use the standard one.
    {programs.ssh.startAgent = lib.mkDefault true;}

    (lib.mkIf hasSddmNew {services.displayManager.sddm.enable = true;})
    (lib.mkIf (!hasSddmNew && hasSddmOld) {services.xserver.displayManager.sddm.enable = true;})

    (lib.mkIf hasPlasmaNew {services.desktopManager.plasma6.enable = true;})
    (lib.mkIf (!hasPlasmaNew && hasPlasmaOld) {services.xserver.desktopManager.plasma6.enable = true;})

    # Avoid accidentally enabling two DMs if something else pulls one in.
    (lib.mkIf hasGdmNew {services.displayManager.gdm.enable = false;})
    (lib.mkIf (!hasGdmNew && hasGdmOld) {services.xserver.displayManager.gdm.enable = false;})
  ]);
}
