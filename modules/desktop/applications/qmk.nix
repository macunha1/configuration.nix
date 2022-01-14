# applications/qmk.nix -- https://qmk.fm/
#

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.desktop.applications.qmk = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.applications.qmk.enable {
    user.packages = with pkgs.unstable; [ qmk qmk-udev-rules ];
  };
}
