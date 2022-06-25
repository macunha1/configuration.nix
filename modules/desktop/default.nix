# desktop -- default configuration among installations
#
# Basics regardless of the installed WM or DE.

{ config, lib, pkgs, ... }:

with lib; {
  options.modules.desktop = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.enable {
    services = {
      xserver = {
        enable = true;

        displayManager.lightdm = {
          enable = true;

          greeters.mini = {
            enable = true;
            user = config.user.name;
          };
        };

        desktopManager.xterm.enable =
          mkDefault (config.modules.desktop.terminal.default == "xterm");
      };
    };

    user.packages = with pkgs; [
      pcmanfm # lightweight file manager
      xfce.xfce4-panel # system trail

      # Screenshooters
      scrot # Lightweight screenshooter
      xfce.xfce4-screenshooter

      feh # Simple image viewer
      xclip # clipboard access from terminal
    ];

    ## Fonts
    fonts = {
      fontDir.enable = true;
      enableGhostscriptFonts = true;

      fonts = with pkgs; [ powerline-fonts source-code-pro ];
      fontconfig.defaultFonts.monospace = [ "Source Code Pro" ];
    };
  };
}
