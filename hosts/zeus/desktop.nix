_: {
  imports = [
    ../../modules/desktop
  ];

  # Swap this line to switch the host between KDE and GNOME.
  local.desktop = "gnome";

  # Auto-login on the selected display manager (GDM/SDDM/etc.).
  services.displayManager.autoLogin = {
    enable = false;
    user = "philipp";
  };
}
