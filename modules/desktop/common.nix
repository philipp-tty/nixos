{
  pkgs,
  lib,
  config,
  ...
}: let
  enabled = config.local.desktop != "none";
in {
  config = lib.mkIf enabled {
    # Needed for Steam/Discord/Chrome/PyCharm (unfree)
    nixpkgs.config.allowUnfree = true;

    services = {
      xserver = {
        enable = true;
        videoDrivers = ["amdgpu"];
      };

      # Flatpak support + Flathub.
      flatpak.enable = true;
    };

    # Add flathub repository and install VS Code via flatpak.
    systemd.services.flatpak-repo = {
      wantedBy = ["multi-user.target"];
      path = [
        pkgs.flatpak
        pkgs.gnugrep
      ];
      script = ''
        # Add flathub repository if not already present
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

        # Install Visual Studio Code via flatpak if not already installed
        if ! flatpak list --app --columns=application | grep -qx com.visualstudio.code; then
          echo "Installing Visual Studio Code via flatpak..."
          flatpak install --noninteractive flathub com.visualstudio.code
        else
          echo "Visual Studio Code is already installed via flatpak"
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    programs = {
      # Used by GNOME and also useful for GTK theming under Plasma.
      dconf.enable = true;

      # Steam
      steam.enable = true;
    };

    hardware = {
      # AMD GPU + Steam/Proton (32-bit userspace)
      graphics = {
        enable = true;
        enable32Bit = true; # helpful for Wine/Steam/Proton
      };

      # RX 7800 XT is RDNA3 (gfx1101). ROCm/OpenCL on NixOS typically uses this switch.
      amdgpu.opencl.enable = true;
    };

    # Ensure desktop apps (GNOME Terminal, VS Code, etc.) have the fonts we reference in dconf/GTK.
    fonts = {
      packages = with pkgs;
        [
          inter
          jetbrains-mono
          noto-fonts
        ]
        ++ lib.optionals (pkgs ? noto-fonts-color-emoji) [noto-fonts-color-emoji]
        ++ lib.optionals (!(pkgs ? noto-fonts-color-emoji) && (pkgs ? noto-fonts-emoji)) [noto-fonts-emoji];

      fontconfig.defaultFonts = {
        sansSerif = ["Inter" "Noto Sans"];
        serif = ["Noto Serif"];
        monospace = ["JetBrains Mono" "DejaVu Sans Mono"];
        emoji = ["Noto Color Emoji"];
      };
    };

    # Packages
    environment.systemPackages = with pkgs;
      [
        # apps
        discord
        vlc
        ffmpeg
        firefox
        google-chrome
        # vscode moved to flatpak - install via: flatpak install flathub com.visualstudio.code
        obsidian
        rustdesk
        remmina
        tigervnc
        turbovnc
        bambu-studio
        usbimager

        # IDE
        jetbrains.pycharm-oss
        jetbrains-toolbox

        # verify ROCm/OpenCL
        clinfo
        rocmPackages.rocminfo
        rocmPackages.rocm-smi

        # tailscale cli
        tailscale

        # GTK theming for non-KDE apps
        adw-gtk3
        papirus-icon-theme
      ]
      # Only install the newer CIDER package when available.
      ++ lib.optionals (pkgs ? cider2) [pkgs.cider2];
  };
}
