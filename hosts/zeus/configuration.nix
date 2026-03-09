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
    ../../modules/emulators
    ../../modules/office
  ];

  local = {
    docker.enable = true;
    rocm_whispercpp.enable = true;
    vulkan.enable = true;
    emulators.enable = true;
    office.enable = true;
  };
}
