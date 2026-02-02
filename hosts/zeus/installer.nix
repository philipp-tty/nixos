{ config, pkgs, lib, modulesPath, ... }:

let
  repoSrc = lib.cleanSource ../../.;
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-gnome.nix"
    ./base.nix
  ];

  # Embed the repo so you can install without cloning.
  isoImage.contents = [
    {
      source = repoSrc;
      target = "/etc/nixos";
    }
  ];
}
