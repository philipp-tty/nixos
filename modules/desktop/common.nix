{
  pkgs,
  pkgsUnstable,
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

      # Printing support
      printing.enable = true;
      avahi = {
        enable = true;
        nssmdns4 = true;
      };
    };

    # Add flathub repository and install RustDesk via flatpak.
    systemd.services.flatpak-repo = {
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      path = [
        pkgs.flatpak
        pkgs.gnugrep
      ];
      script = ''
        # Add flathub repository if not already present
        flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

        # Install RustDesk via flatpak if not already installed
        if ! flatpak list --system --app --columns=application | grep -qx com.rustdesk.RustDesk; then
          echo "Installing RustDesk via flatpak..."
          flatpak install --system --noninteractive flathub com.rustdesk.RustDesk
        else
          echo "RustDesk is already installed via flatpak"
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
          nerd-fonts.jetbrains-mono
          noto-fonts
        ]
        ++ lib.optionals (pkgs ? noto-fonts-color-emoji) [noto-fonts-color-emoji]
        ++ lib.optionals (!(pkgs ? noto-fonts-color-emoji) && (pkgs ? noto-fonts-emoji)) [noto-fonts-emoji];

      fontconfig.defaultFonts = {
        sansSerif = ["Inter" "Noto Sans"];
        serif = ["Noto Serif"];
        monospace = ["JetBrainsMono Nerd Font Mono" "JetBrains Mono" "DejaVu Sans Mono"];
        emoji = ["Noto Color Emoji"];
      };
    };

    # Packages
    environment.systemPackages = with pkgs; [
      # apps
      discord
      vlc
      ffmpeg
      firefox
      google-chrome
      # Keep VS Code on a newer track than the base system channel.
      pkgsUnstable.vscode
      obsidian
      # rustdesk moved to flatpak - install via: flatpak install flathub com.rustdesk.RustDesk
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

      # tailscale
      tailscale
      tailscale-systray
      trayscale

      # GTK theming for non-KDE apps
      adw-gtk3
      papirus-icon-theme

      # music
      cider-2

      # printing
      cups-filters
      ghostscript
    ];
  };
}
