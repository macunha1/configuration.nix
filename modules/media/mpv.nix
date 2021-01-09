# media/mpv.nix -- https://mpv.io/
#
# Minimal and extensible open-source media player

{ config, options, lib, pkgs, ... }:

with lib; {
  options.modules.media.mpv = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.media.mpv.enable {
    user.packages = with pkgs; [
      mpv # video player
      (mpv-with-scripts.override {
        # Adds support for DBus and controls over playerctl
        scripts = [ mpvScripts.mpris ];
      })
    ];
  };
}
