_: {
  home = {
    username = "philipp";
    homeDirectory = "/home/philipp";
    stateVersion = "25.11"; # Adjust to the NixOS release you first installed.
  };

  programs.home-manager.enable = true;

  # Theme GTK apps consistently under Plasma (and other DEs).
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-light";
      gtk-theme = "adw-gtk3";
      icon-theme = "Papirus";
    };
  };
}
