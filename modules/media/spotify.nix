{ config, options, lib, pkgs, ... }:
with lib; {
  # TODO: Include Spicetify CLI for Official Spotify client theme configuration
  options.modules.media.spotify = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

    daemon = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf config.modules.media.spotify.enable {
    my = {
      packages = with pkgs; [ pkgs.unstable.spotify ];

      home.services.spotifyd = {
        enable = config.modules.media.spotify.daemon.enable;

        package = (pkgs.unstable.spotifyd.override { withMpris = true; });
        settings = {
          global = {
            username = "22l46w473dznfqimcwcetx4sa";
            password_cmd = "pass show spotify/macunha";
          };
        };
      };
    };

    # Allows to control player over DBus
    services.dbus.socketActivated = true;
  };
}
