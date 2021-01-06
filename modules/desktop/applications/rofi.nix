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

    theme = mkOption {
      type = types.str;
      default = "retrowave";
    };
  };

  config = mkIf config.modules.desktop.applications.rofi.enable {
    user.packages = [
      pkgs.rofi # TUI all the things
    ];

    home.configFile."rofi/config.rasi" = {
      text = ''
        configuration {
            modi: "window,drun,combi";
            theme: "${config.modules.desktop.applications.rofi.theme}";
            font: "Source Code Pro 10";
            combi-modi: "window,drun";
        }
      '';
    };

    home.configFile."rofi" = {
      source = <config/rofi>;
      # Write it recursively to not overwritte other modules
      recursive = true;
    };
  };
}
