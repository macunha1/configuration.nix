# media/spotify.nix -- https://www.spotify.com/
#
# Official Spotify media player implemented in Electron that works just as
# shitty as expected. Apart from the official Spotify media player, Spotify
# daemon is also installed that could be extended with Spotify TUI
# Ref: https://github.com/Spotifyd/spotifyd

{ config, options, lib, pkgs, ... }:
with lib; {
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

      settings = mkOption {
        type = types.attrsOf (types.attrsOf types.str);
        default = { };
        example = literalExpression ''
          {
            global = {
              username = "janedoe";
              password = "secret";
            };
          }
        '';
      };
    };
  };

  config = mkIf config.modules.media.spotify.enable {
    user.packages = with pkgs; [ pkgs.unstable.spotify ];

    # home.services.spotifyd = {
    #   enable = config.modules.media.spotify.daemon.enable;

    #   package = (pkgs.unstable.spotifyd.override { withMpris = true; });
    #   settings = config.modules.media.spotify.daemon.settings;
    # };

    # no longer necessary: the user D-Bus session is always socket activated
    # with home-manager as of this writing.
    # services.dbus.socketActivated = true;
  };
}
