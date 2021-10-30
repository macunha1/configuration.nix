# media/spotify.nix -- https://www.spotify.com/
#
# Official Spotify media player implemented in Electron that works just as
# shitty as expected. Apart from the official Spotify media player, Spotify
# daemon is also installed that could be extended with Spotify TUI
# Ref: https://github.com/Spotifyd/spotifyd

{ config, home-manager, options, lib, pkgs, ... }:
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

        # NOTE: Remember that when using a password manager such as `pass` with
        # a passphrase protected GPG key the service won't start on its own.
        # Therefore you need to enter the passphrase through a pinentry and
        # restart it manually.

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

  config = mkIf config.modules.media.spotify.enable (mkMerge [
    { user.packages = with pkgs; [ pkgs.spotify ]; }

    (mkIf config.modules.media.spotify.daemon.enable {
      # When using the Daemon, install the Spotify TUI together to work as an
      # alternative client..
      user.packages = with pkgs; [ pkgs.spotify-tui ];

      home-manager.users.${config.user.name}.services.spotifyd = {
        enable = true;

        package = (pkgs.spotifyd.override { withMpris = true; });
        settings = config.modules.media.spotify.daemon.settings;
      };
    })
  ]);
}
