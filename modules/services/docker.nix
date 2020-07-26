{ config, options, pkgs, lib, ... }:
with lib;
{
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
  };

  config = mkIf config.modules.services.docker.enable {
    my = {
      packages = with pkgs; [
        docker
        docker-compose
        buildah
      ];

      # Manage env append file to $HOME/.profiles.d/docker.sh
      # env.MACHINE_STORAGE_PATH = "$XDG_DATA_HOME/docker/machine";
      # env.DOCKER_CONFIG = "$XDG_CONFIG_HOME/docker";

      user.extraGroups = [ "docker" ];
    };

    virtualisation = {
      docker = {
        enable = true;
        autoPrune.enable = true;
        enableNvidia = config.modules.services.docker.nvidia.enable;
        enableOnBoot = config.modules.services.docker.onBoot.enable;
      };
    };
  };
}
