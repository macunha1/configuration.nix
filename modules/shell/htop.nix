{ config, options, pkgs, lib, ... }:
with lib;
{
  options.modules.shell.htop = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.shell.htop.enable {
    my = {
      packages = with pkgs; [
        htop
      ];
    };
  };
}
