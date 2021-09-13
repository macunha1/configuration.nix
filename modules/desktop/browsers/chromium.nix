# modules/browser/chromium.nix -- https://www.chromium.org/
#
# Open-source project that Google acquired to create Google Chrome, although it
# requires as much RAM as the commercial version Chromium provides a fast engine
# and GPU processing capabilities which are IMHO big selling points in
# comparison to Firefox.

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.desktop.browsers.chromium = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.browsers.chromium.enable {
    user.packages = with pkgs; [ unstable.chromium ];

    # TODO: Include portable and reusable Chromium configuration
    # home.home.file = { };
  };
}
