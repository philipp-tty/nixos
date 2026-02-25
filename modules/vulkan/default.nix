{
  config,
  lib,
  pkgs,
  ...
}: let
  enabled = config.local.vulkan.enable;
in {
  options.local.vulkan.enable = lib.mkEnableOption "Vulkan support tooling";

  config = lib.mkIf enabled {
    # Ensure graphics stack is enabled for Vulkan userspace.
    hardware.graphics.enable = lib.mkDefault true;

    environment.systemPackages = with pkgs; [
      vulkan-tools
      vulkan-loader
    ];
  };
}
