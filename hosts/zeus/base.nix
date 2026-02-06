{...}: {
  networking.hostName = "zeus";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  # Nix: flakes + binary caches (prefer substitutes to avoid local builds).
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];

    # Keep the official NixOS cache and add nix-community for common community packages.
    extra-substituters = ["https://nix-community.cachix.org"];
    extra-trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
  };

  # Bootloader (UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # SSH
  services.openssh.enable = true;

  # Tailscale
  services.tailscale.enable = true;

  users.users.philipp = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
  };

  system.stateVersion = "25.11"; # Adjust to the NixOS release you first installed.
}
