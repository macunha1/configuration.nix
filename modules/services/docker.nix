{ config, options, pkgs, lib, ... }:
with lib; {
  options.modules.services.docker = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    nvidia.enable = mkOption {
      type = types.bool;
      default = false;
    };

    onBoot.enable = mkOption {
      type = types.bool;
      default = false;
    };

    storagePath = mkOption {
      type = types.path;
      default = "/var/lib/docker";
    };
  };

  config = mkIf config.modules.services.docker.enable {
    my = {
      packages = with pkgs; [ docker docker-compose buildah ];

      env.MACHINE_STORAGE_PATH = config.modules.services.docker.storagePath;
      env.DOCKER_CONFIG = "$XDG_CONFIG_HOME/docker";

      user.extraGroups = [ "docker" ];
    };

    virtualisation = {
      docker = {
        enable = true;
        autoPrune.enable = true;

        extraOptions = "-g ${config.modules.services.docker.storagePath}";
        package = pkgs.unstable.docker;
        enableNvidia = config.modules.services.docker.nvidia.enable;
        enableOnBoot = config.modules.services.docker.onBoot.enable;
      };
    };
  };
}
