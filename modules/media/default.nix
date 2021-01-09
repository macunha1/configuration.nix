# media -- default media players config among installations

{ config, options, lib, pkgs, ... }:

with lib; {
  options.modules.media = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.media.enable {
    user.packages = with pkgs;
      [
        playerctl # One controller to rule them all
      ];
  };
}
