# virtualization/docker.nix -- https://www.docker.com/
#
# Docker container engine, the kick start towards popularization of Linux
# Containers for developers. Docker Inc. did a great job democratizing access to
# Linux Containers and then donating "Docker v2 spec" to the Linux Foundation as
# the OCI.
# Ref: https://opencontainers.org/
#
# In a near future this module might be deprecated to give space for an
# implementation using alternative tools, such as runc
# Ref: https://github.com/opencontainers/runc

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
      type = with types; (either str path);
      default = "/var/lib/docker";
    };
  };

  config = mkIf config.modules.virtualization.docker.enable {
    user = {
      packages = with pkgs; [ docker ];
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
