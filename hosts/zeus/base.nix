{pkgs, ...}: let
  reboot-to-windows = pkgs.writeShellApplication {
    name = "reboot-to-windows";
    runtimeInputs = with pkgs; [systemd];
    text = builtins.readFile ../../scripts/reboot-to-windows.sh;
  };
in {
  # Needed for Steam/Discord/Chrome and some desktop themes/cursors (unfree)
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "zeus";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  environment.systemPackages = with pkgs; [
    htop
    neovim
    yt-dlp
    reboot-to-windows
  ];

  # System-wide AppImage support (adds `appimage-run` and optional binfmt integration).
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  programs.zsh.enable = true;

  # Nix: flakes + binary caches (prefer substitutes to avoid local builds).
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];

    # Keep the official NixOS cache and add nix-community for common community packages.
    extra-substituters = ["https://nix-community.cachix.org"];
    extra-trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
  };

  # Bootloader (UEFI)
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };

      efi.canTouchEfiVariables = true;
    };
  };

  # Keep old NixOS system generations from accumulating forever.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # SSH
  services.openssh.enable = true;

  # Tailscale
  services.tailscale.enable = true;

  users.users.philipp = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
    shell = pkgs.zsh;
  };

  system.stateVersion = "25.11"; # Adjust to the NixOS release you first installed.
}
