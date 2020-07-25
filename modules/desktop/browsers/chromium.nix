# modules/browser/chromium.nix --- https://www.chromium.org/

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.desktop.browsers.chromium = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    profileName = mkOption {
      type = types.str;
      default = config.my.username;
    };
  };

  config = mkIf config.modules.desktop.browsers.chromium.enable {
    my.packages = with pkgs; [
      chromium
    ];

    # Use a stable profile name so we can target it in themes
    my.home.home.file =
      let cfg = config.modules.desktop.browsers.chromium; in
      {  }; # TODO: Include Chromium configuration
  };
}
