{ config, options, lib, pkgs, ... }:

with lib;
{
  imports = [
    ./mpv.nix
    ./spotify.nix
  ];

  options.modules.media = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.media.enable {
    my.packages = with pkgs; [
      playerctl # One controller to rule them all
    ];
  };
}
