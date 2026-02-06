_: {
  home = {
    username = "philipp";
    homeDirectory = "/home/philipp";
    stateVersion = "25.11"; # Adjust to the NixOS release you first installed.
  };

  programs.home-manager.enable = true;

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-light";
      gtk-theme = "adw-gtk3";
      icon-theme = "Papirus";
    };
    "org/gnome/desktop/session" = {
      # OLED burn-in mitigation: blank quickly when idle.
      idle-delay = 300; # seconds
    };
    "org/gnome/desktop/screensaver" = {
      lock-enabled = true;
      lock-delay = 60; # seconds after blanking
    };
    "org/gnome/settings-daemon/plugins/power" = {
      idle-dim = true;
    };
    "org/gnome/desktop/wm/preferences" = {
      # macOS-style window buttons on the left
      button-layout = "close,minimize,maximize:";
    };
    "org/gnome/mutter" = {
      center-new-windows = true;
      experimental-features = ["scale-monitor-framebuffer" "variable-refresh-rate"];
    };
    "org/gnome/shell" = {
      enabled-extensions = [
        "dash-to-dock@micxgx.gmail.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
      ];
    };
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "BOTTOM";
      dock-fixed = false;
      autohide = true;
      dash-max-icon-size = 48;
      click-action = "minimize";
      show-trash = false;
      show-mounts = false;
    };
  };
}
