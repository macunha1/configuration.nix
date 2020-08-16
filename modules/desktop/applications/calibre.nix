{ config, options, pkgs, lib, ... }:
with lib; {
  options.modules.desktop.applications.calibre = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.applications.calibre.enable {
    my.packages = [
      pkgs.calibre # ebooks manager
    ];
  };
}
