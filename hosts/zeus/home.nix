{ config, pkgs, ... }:

{
  home.username = "philipp";
  home.homeDirectory = "/home/philipp";
  home.stateVersion = "25.11"; # Adjust to the NixOS release you first installed.

  programs.home-manager.enable = true;
}
