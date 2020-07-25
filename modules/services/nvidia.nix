{ config, options, lib, pkgs, ... }:

with lib;
{
  options.modules.desktop.nvidia = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };
  
  config = mkIf config.modules.desktop.nvidia.enable {
    nixpkgs.config.allowUnfree = true;

    ## X Window Server
    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
