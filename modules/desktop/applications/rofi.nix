# modules/applications/rofi.nix --- https://github.com/davatorium/rofi
#
# A window switcher, Application launcher and dmenu replacement

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.desktop.applications.rofi = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.applications.rofi.enable {
    my = {
      packages = [
        pkgs.rofi # TUI all the things
      ];

      home.xdg.configFile."rofi" = {
        source = <config/rofi>;
        # Write it recursively to not overwritte other modules
        recursive = true;
      };
    };
  };
}
