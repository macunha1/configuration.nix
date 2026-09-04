# applications/qmk.nix -- https://qmk.fm/
#
# QMK is firmware tooling for custom mechanical keyboards. This module installs
# the CLI and udev rules needed to build, flash, and configure supported boards.

{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.modules.desktop.applications.qmk = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.applications.qmk.enable {
    user.packages = [
      (pkgs.qmk.override {
        # AVRDUDE documentation pulls in a broken TeX/PyQt5 build on Python 3.14.
        avrdude = pkgs.avrdude.override { docSupport = false; };
      })
      pkgs.qmk-udev-rules
    ];
  };
}
