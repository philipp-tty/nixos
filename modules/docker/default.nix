{
  config,
  lib,
  pkgs,
  ...
}: let
  enabled = config.local.docker.enable;
in {
  options.local.docker.enable = lib.mkEnableOption "Docker engine and CLI tooling";

  config = lib.mkIf enabled {
    virtualisation = {
      containers.enable = true;
      docker = {
        enable = true;
        enableOnBoot = true;
        autoPrune.enable = true;
      };
    };

    # Keep classic `docker-compose` available alongside `docker compose`.
    environment.systemPackages = with pkgs; [docker-compose];

    users.users.philipp.extraGroups = lib.mkAfter ["docker"];
  };
}
