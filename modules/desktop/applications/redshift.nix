# modules/applications/redshift.nix --- http://jonls.dk/redshift/
#
# Redshift adjusts screen color according to sun's position given a lat/long of
# an Earth location for the observer. If you're from the future and live in
# Mars, I'm sorry, at the time of this writing only Earth is supported.

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.desktop.applications.redshift = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    latitude = mkOption {
      type = types.str;
      default = "48.1";
    };

    longitude = mkOption {
      type = types.str;
      default = "11.6";
    };

    temperature = {
      day = mkOption {
        type = types.int;
        default = 3245;
      };

      night = mkOption {
        type = types.int;
        default = 2897;
      };
    };
  };

  config = mkIf config.modules.desktop.applications.redshift.enable {
    user.packages = with pkgs; [ redshift ];

    home-manager.users.${config.user.name}.services.redshift = {
      enable = true;
      latitude = config.modules.desktop.applications.redshift.latitude;
      longitude = config.modules.desktop.applications.redshift.longitude;

      temperature = {
        day = config.modules.desktop.applications.redshift.temperature.day;
        night = config.modules.desktop.applications.redshift.temperature.night;
      };
    };
  };
}
