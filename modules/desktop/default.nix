# desktop -- default configuration among installations
#
# Basics regardless of the installed WM or DE.

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
{
  options.modules.desktop = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.enable {
    services = {
      displayManager.ly = {
        enable = true;
        x11Support = true;
      };

      xserver = {
        enable = true;

        desktopManager.xterm.enable = mkDefault (config.modules.desktop.terminal.default == "xterm");
      };
    };

    user.packages = with pkgs; [
      pcmanfm # lightweight file manager
      xfce4-panel # system trail

      # Screenshooters
      scrot # Lightweight screenshooter
      xfce4-screenshooter

      feh # Simple image viewer
      xclip # clipboard access from terminal
    ];

    # Fonts
    fonts = {
      fontDir.enable = true;
      enableGhostscriptFonts = true;

      packages = with pkgs; [
        powerline-fonts
        source-code-pro
      ];
      fontconfig.defaultFonts.monospace = [ "Source Code Pro" ];
    };
  };
}
