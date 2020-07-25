# modules/applications/uhk-agent.nix --- https://ultimatehackingkeyboard.com/

{ config, options, lib, pkgs, ... }:
with lib;
{
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
    my.packages = with pkgs; [
      # pkgs.uhkAgent
    ];

    # services.udev.packages = with pkgs; [ pkgs.uhkAgent ];
  };
}
