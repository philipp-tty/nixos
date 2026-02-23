_: {
  imports = [
    ./hardware-configuration.nix
    ./base.nix
    ./desktop.nix
    ./developer.nix
    ./simulation.nix
    ../../modules/docker
  ];

  local.docker.enable = true;
}
