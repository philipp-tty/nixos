{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.local.rocm_whispercpp;

  whispercpp-gpu = pkgs.whisper-cpp.override {
    rocmSupport = true;
    vulkanSupport = true;
    inherit (pkgs) rocmPackages;
  };
in {
  options.local.rocm_whispercpp = {
    enable = lib.mkEnableOption "ROCm/Vulkan-accelerated whisper-cpp";

    rocmTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["gfx1101"];
      example = ["gfx1101"];
      description = "ROCm GPU targets used when building ROCm packages (RX 7800 XT = gfx1101).";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config = {
      rocmSupport = true;
      inherit (cfg) rocmTargets;
    };

    environment.systemPackages = [
      # Provide ffmpeg CLI for audio conversion/pre-processing with whisper workflows.
      pkgs.ffmpeg
      whispercpp-gpu
    ];
  };
}
