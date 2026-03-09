{
  config,
  lib,
  pkgs,
  ...
}: let
  enabled = config.local.office.enable;
in {
  options.local.office.enable = lib.mkEnableOption "Office and PDF tooling";

  config = lib.mkIf enabled {
    environment.systemPackages = with pkgs; [
      libreoffice
      poppler-utils
      qpdf
      pdftk
      ghostscript
    ];
  };
}
