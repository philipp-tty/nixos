{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./base.nix
  ];
}
