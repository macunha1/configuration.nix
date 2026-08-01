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
    # Enable the dconf service used by the user-level desktop preferences.
    programs.dconf.enable = true;

    services = {
      # X resources take precedence over XCURSOR_THEME for many X11 clients.
      # Apply the cursor theme during session startup so the window manager and
      # applications agree on the same cursor set.
      xserver.displayManager.sessionCommands = mkAfter ''
        printf '%s\n' \
          'Xcursor.theme: Adwaita' \
          'Xcursor.size: 24' | ${pkgs.xrdb}/bin/xrdb -merge
      '';

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
      adwaita-icon-theme
      pcmanfm # lightweight file manager
      xfce4-panel # system trail

      # Screenshooters
      scrot # Lightweight screenshooter
      xfce4-screenshooter

      feh # Simple image viewer
      xclip # clipboard access from terminal
    ];

    environment.variables = {
      # Keep GTK applications, including the lightweight file manager, dark.
      GTK_THEME = "Adwaita:dark";
      XCURSOR_THEME = "Adwaita";
      XCURSOR_SIZE = "24";
      XCURSOR_PATH = mkForce "${pkgs.adwaita-icon-theme}/share/icons";
    };

  };
}
