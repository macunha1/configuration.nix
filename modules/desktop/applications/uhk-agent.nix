# applications/uhk-agent.nix -- https://ultimatehackingkeyboard.com/
#
# Ultimate Hacking Keyboard Agent provides a user friendly interface to
# customize the UHK Keyboard settings. As a former Vortex Pok3r owner I can say
# that it makes life better.

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.desktop.applications.uhkAgent = {
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

  config = mkIf config.modules.desktop.applications.uhkAgent.enable {
    user.packages = with pkgs; [ my.uhk-agent ];

    services.udev.packages = with pkgs; [ my.uhk-agent ];
  };
}
