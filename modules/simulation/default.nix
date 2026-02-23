{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.local.simulation;
in {
  options.local.simulation = {
    enable = lib.mkEnableOption "Simulation tooling";
    paraview.enable = lib.mkEnableOption "ParaView post-processing and visualization";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf cfg.paraview.enable {
      environment.systemPackages = with pkgs; [
        paraview
      ];
    })
  ]);
}
