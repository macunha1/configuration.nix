{ config, options, lib, pkgs, ... }:

with lib;
{
  options.modules.media.mpv = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.media.mpv.enable {
    my.packages = with pkgs; [
      mpv     # video player
      (mpv-with-scripts.override {
        # Adds support for DBus and controls over playerctl
        scripts = [ mpvScripts.mpris ];
      })
    ];
  };
}
