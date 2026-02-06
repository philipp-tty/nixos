{ config, pkgs, ... }:

{
  networking.hostName = "zeus";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  # Needed for Steam/Discord/Chrome/PyCharm (unfree)
  nixpkgs.config.allowUnfree = true;

  # Nix: flakes + binary caches (prefer substitutes to avoid local builds).
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

    # Keep the official NixOS cache and add nix-community for common community packages.
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Bootloader (UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # GNOME
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = true;
  services.desktopManager.gnome.enable = true;
  programs.dconf.enable = true;

  # AMD GPU + Steam/Proton (32-bit userspace)
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true; # helpful for Wine/Steam/Proton
  services.xserver.videoDrivers = [ "amdgpu" ];

  # RX 7800 XT is RDNA3 (gfx1101). ROCm/OpenCL on NixOS typically uses this switch.
  hardware.amdgpu.opencl.enable = true;

  # Steam
  programs.steam.enable = true;

  # SSH
  services.openssh.enable = true;
  # GNOME enables gcr-ssh-agent; avoid a second SSH agent.
  programs.ssh.startAgent = false;

  # Tailscale
  services.tailscale.enable = true;

  users.users.philipp = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # Packages
  environment.systemPackages = with pkgs; [
    # dev
    python3
    nodejs
    git
    gh
    codex
    micromamba

    # apps
    discord
    vlc
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

  system.stateVersion = "25.11"; # Adjust to the NixOS release you first installed.
}
