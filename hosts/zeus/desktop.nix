{pkgs, lib, ...}: {
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
    vscode
    obsidian
    rustdesk
    remmina
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
  ++ lib.optionals (!(pkgs ? cider2) && (pkgs ? cider)) [pkgs.cider];
}
