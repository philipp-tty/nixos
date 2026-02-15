_: {
  imports = [
    ./hardware-configuration.nix
    ./base.nix
    ./desktop.nix
    ./developer.nix
    ../../modules/docker
  ];

  local.docker.enable = true;
}
