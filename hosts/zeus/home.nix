{
  pkgs,
  lib,
  ...
}: {
  home = {
    username = "philipp";
    homeDirectory = "/home/philipp";
    stateVersion = "25.11";

    packages = with pkgs; [
      # macOS-inspired GTK theme & icons
      whitesur-gtk-theme
      kdePackages.breeze-icons
      apple-cursor

      # GNOME extensions for the macOS workflow
      gnomeExtensions.dash-to-dock
      gnomeExtensions.just-perfection
      gnomeExtensions.blur-my-shell
      gnomeExtensions.user-themes
    ];
  };

  programs.home-manager.enable = true;

  # ── GTK / libadwaita theming ──────────────────────────────────────────
  gtk = {
    enable = true;
    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme;
    };
    iconTheme = {
      name = "breeze-dark";
      package = pkgs.kdePackages.breeze-icons;
    };
    cursorTheme = {
      name = "macOS";
      package = pkgs.apple-cursor;
      size = 24;
    };
  };

  # Force dark style for libadwaita / GTK 4 apps
  dconf.settings = let
    gv = lib.hm.gvariant;
  in {
    # ── Dark mode ───────────────────────────────────────────────────────
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "WhiteSur-Dark";
      icon-theme = "breeze-dark";
      cursor-theme = "macOS";
      cursor-size = 24;
      font-name = "Inter 11";
      document-font-name = "Inter 11";
      monospace-font-name = "JetBrains Mono 10";
      # Hot-corner off – avoids accidental overview on OLED static area
      enable-hot-corners = false;
      enable-animations = true;
      # Reduce OLED wear from overly bright accents
      accent-color = "slate";
    };

    # macOS-style window buttons: close | minimize | maximize on the LEFT
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "close,minimize,maximize:";
      titlebar-font = "Inter Bold 11";
    };

    # ── Shell extensions ────────────────────────────────────────────────
    "org/gnome/shell" = {
      enabled-extensions = [
        "dash-to-dock@micxgx.gmail.com"
        "just-perfection-desktop@just-perfection"
        "blur-my-shell@aunetx"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
      ];
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "firefox.desktop"
        "code.desktop"
      ];
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "WhiteSur-Dark";
    };

    # ── Just Perfection – kill the top bar ──────────────────────────────
    "org/gnome/shell/extensions/just-perfection" = {
      panel = false; # hide top bar entirely
      panel-in-overview = true; # keep it visible in overview only
      activities-button = false;
      app-menu = false;
      clock-menu = false;
      keyboard-layout = false;
      accessibility-menu = false;
      # Sleek animation tweaks
      animation = 3; # faster animations
      startup-status = 0; # skip overview on login
      notification-banner-position = 2; # top-right, out of the way
    };

    # ── Dash to Dock – auto-hiding bottom dock ─────────────────────────
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "BOTTOM";
      dock-fixed = false;
      autohide = true;
      intellihide = true;
      animation-time = 0.15;
      hide-delay = 0.2;
      show-delay = 0.15;
      dash-max-icon-size = 48;
      height-fraction = 0.9;
      # Translucent blurred background
      background-opacity = 0.55;
      transparency-mode = "DYNAMIC";
      custom-background-color = false;
      # Minimal, macOS-style indicators
      running-indicator-style = "DOTS";
      custom-theme-shrink = true;
      show-trash = false;
      show-mounts = false;
      apply-custom-theme = false;
      extend-height = false;
      # Scroll action
      scroll-action = "cycle-windows";
    };

    # ── Blur my Shell – frosted-glass everywhere ────────────────────────
    "org/gnome/shell/extensions/blur-my-shell" = {
      brightness = 0.55;
      sigma = 40; # heavy blur for OLED depth look
      noise-amount = 0.0;
    };
    "org/gnome/shell/extensions/blur-my-shell/overview" = {
      blur = true;
      style-components = 1;
    };
    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur = true;
      brightness = 0.5;
      sigma = 40;
      override-background = true;
      style-dash-to-dock = 0;
    };

    # ── OLED burn-in protection ─────────────────────────────────────────
    # Short idle → dim → blank chain keeps static pixels off
    "org/gnome/desktop/session" = {
      idle-delay = gv.mkUint32 180; # dim after 3 min
    };
    "org/gnome/settings-daemon/plugins/power" = {
      idle-dim = true;
      ambient-enabled = true;
      sleep-inactive-ac-timeout = 600; # suspend after 10 min (AC)
      sleep-inactive-ac-type = "suspend";
      sleep-inactive-battery-timeout = 300; # suspend after 5 min (battery)
      sleep-inactive-battery-type = "suspend";
      power-button-action = "suspend";
    };
    "org/gnome/desktop/screensaver" = {
      lock-enabled = true;
      lock-delay = gv.mkUint32 15; # lock 15 s after blank
      idle-activation-enabled = true;
    };

    # Night-light (disabled)
    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = false;
      night-light-schedule-automatic = false;
      night-light-temperature = gv.mkUint32 3200;
    };

    # ── Workspace & window behaviour ────────────────────────────────────
    "org/gnome/mutter" = {
      dynamic-workspaces = true;
      edge-tiling = true;
    };
  };
}
