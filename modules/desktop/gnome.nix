{
  lib,
  config,
  options,
  pkgs,
  ...
}: let
  enabled = config.local.desktop == "gnome";

  hasGdmNew = lib.hasAttrByPath ["services" "displayManager" "gdm" "enable"] options;
  hasGdmOld = lib.hasAttrByPath ["services" "xserver" "displayManager" "gdm" "enable"] options;

  hasGnomeNew = lib.hasAttrByPath ["services" "desktopManager" "gnome" "enable"] options;
  hasGnomeOld = lib.hasAttrByPath ["services" "xserver" "desktopManager" "gnome" "enable"] options;

  hasSddmNew = lib.hasAttrByPath ["services" "displayManager" "sddm" "enable"] options;
  hasSddmOld = lib.hasAttrByPath ["services" "xserver" "displayManager" "sddm" "enable"] options;
in {
  config = lib.mkIf enabled (lib.mkMerge [
    {
      assertions = [
        {
          assertion = hasGdmNew || hasGdmOld;
          message = "GNOME selected (local.desktop = \"gnome\"), but GDM option path not found in this nixpkgs.";
        }
        {
          assertion = hasGnomeNew || hasGnomeOld;
          message = "GNOME selected (local.desktop = \"gnome\"), but GNOME desktop option path not found in this nixpkgs.";
        }
      ];
    }

    {
      environment.systemPackages = with pkgs; [
        gnome-tweaks
        gnome-extension-manager
        gnomeExtensions.appindicator
      ];
    }

    (lib.mkIf hasGdmNew {services.displayManager.gdm.enable = true;})
    (lib.mkIf (!hasGdmNew && hasGdmOld) {services.xserver.displayManager.gdm.enable = true;})

    (lib.mkIf hasGnomeNew {services.desktopManager.gnome.enable = true;})
    (lib.mkIf (!hasGnomeNew && hasGnomeOld) {services.xserver.desktopManager.gnome.enable = true;})

    # Avoid accidentally enabling two DMs if something else pulls one in.
    (lib.mkIf hasSddmNew {services.displayManager.sddm.enable = false;})
    (lib.mkIf (!hasSddmNew && hasSddmOld) {services.xserver.displayManager.sddm.enable = false;})
  ]);
}
