{pkgs, lib, config, ...}: {
  # Needed for Steam/Discord/Chrome/PyCharm (unfree)
  nixpkgs.config.allowUnfree = true;

  services = {
    xserver = {
      enable = true;
      videoDrivers = ["amdgpu"];
    };

    # KDE Plasma
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;

    # Flatpak support
    flatpak.enable = true;
  };

  # Add flathub repository and install VS Code via flatpak
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      # Install Visual Studio Code via flatpak
      flatpak install -y --noninteractive flathub com.visualstudio.code || true
    '';
  };

  programs = {
    dconf.enable = true;

    ssh.startAgent = true;

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

  # Packages
  environment.systemPackages = with pkgs; [
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
  # `cider2` isn't available in all nixpkgs revisions; fall back to `cider` when present.
  ++ lib.optionals (pkgs ? cider2) [pkgs.cider2]
  ++ lib.optionals (!(pkgs ? cider2) && (pkgs ? cider)) [pkgs.cider]
  # Install GNOME Extensions when GNOME desktop is enabled
  ++ lib.optionals (config.services.xserver.desktopManager.gnome.enable or false) [
    pkgs.gnome-extension-manager
    pkgs.gnomeExtensions.appindicator
  ];
}
