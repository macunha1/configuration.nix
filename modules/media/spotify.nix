{ config, options, lib, pkgs, ... }:
with lib;
{
  # TODO: Include Spicetify support and theme configuration
  options.modules.media.spotify = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.media.spotify.enable {
    my.packages = with pkgs; [
      spotify
    ];

    # Allows to control player over DBus
    services.dbus.socketActivated = true;
  };
}
