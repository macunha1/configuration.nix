{ config, options, pkgs, lib, ... }:
with lib;
{
  options.modules.services.calibre = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.services.calibre.enable {
    my.packages = with pkgs; [
      calibre # ebooks manager
    ];
  };
}
