_: {
  imports = [
    ./hardware-configuration.nix
    ./base.nix
    ./desktop.nix
    ./developer.nix
    ./simulation.nix
    ../../modules/docker
    ../../modules/rocm_whispercpp
    ../../modules/vulkan
  ];

  local.docker.enable = true;
  local.rocm_whispercpp.enable = true;
  local.vulkan.enable = true;
}
