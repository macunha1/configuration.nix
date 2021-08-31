# modules/browser/firefox.nix -- https://www.firefox.org/
#

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.desktop.browsers.firefox = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.browsers.firefox.enable {
    user.packages = with pkgs; [ firefox ];

    # TODO: Include portable and reusable firefox configuration
    # home.home.file = { };
  };
}
