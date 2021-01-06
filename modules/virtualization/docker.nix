{ config, options, pkgs, lib, ... }:
with lib; {
  options.modules.virtualization.docker = {
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

  config = mkIf config.modules.virtualization.docker.enable {
    user = {
      packages = with pkgs; [ docker docker-compose buildah ];
      extraGroups = [ "docker" ];
    };

    env.MACHINE_STORAGE_PATH = config.modules.virtualization.docker.storagePath;
    env.DOCKER_CONFIG = "$XDG_CONFIG_HOME/docker";

    virtualisation = {
      docker = {
        enable = true;
        autoPrune.enable = true;

        extraOptions = "-g ${config.modules.virtualization.docker.storagePath}";
        package = pkgs.unstable.docker;
        enableNvidia = config.modules.virtualization.docker.nvidia.enable;
        enableOnBoot = config.modules.virtualization.docker.onBoot.enable;
      };
    };
  };
}
