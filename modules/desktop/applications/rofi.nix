# applications/rofi.nix -- https://github.com/davatorium/rofi
#
# A window switcher, Application launcher and dmenu replacement
# Rofi could even be described as a TUI framework. Creates minimal and
# performatic UI for commonly used Linux tools, fitting perfectly with a Window
# manager setup.

{ config, options, lib, pkgs, ... }:
with lib;
with lib.my; {
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
      source = "${configDir}/rofi";
      # Write it recursively to not overwritte other modules
      recursive = true;
    };
  };
}
