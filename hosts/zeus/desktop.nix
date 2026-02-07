{pkgs, ...}: {
  # Needed for Steam/Discord/Chrome/PyCharm (unfree)
  nixpkgs.config.allowUnfree = true;

  services = {
    # GNOME
    xserver = {
      enable = true;
      videoDrivers = ["amdgpu"];
    };
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    desktopManager.gnome.enable = true;
  };

  programs = {
    dconf.enable = true;

    # GNOME enables gcr-ssh-agent; avoid a second SSH agent.
    ssh.startAgent = false;

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
    cider
    vscode
    obsidian
    rustdesk
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

    # GNOME look & feel (macOS-ish)
    gnome-tweaks
    adw-gtk3
    papirus-icon-theme
    gnomeExtensions.dash-to-dock
    gnomeExtensions.user-themes
  ];
}
