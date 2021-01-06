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
        example = literalExample ''
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

    # Allows to control player over DBus
    services.dbus.socketActivated = true;
  };
}
