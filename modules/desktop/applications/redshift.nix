# modules/applications/uhk-agent.nix --- https://ultimatehackingkeyboard.com/

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.desktop.applications.redshift = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    version = mkOption {
      type = types.str;
      # version >1.3.0 causes it to hang on launch ("Loading configuration. Hang on")
      default = "1.3.0";
    };
  };

  config = mkIf config.modules.desktop.applications.redshift.enable {
    my = {
      packages = with pkgs; [
        redshift
      ];

      home.services.redshift = {
        enable = true;
        latitude = "48.1";
        longitude = "11.6";

        temperature = {
          day = 3245;
          night = 2897;
        };
      };
    };
  };
}
