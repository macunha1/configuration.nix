{ options, config, lib, pkgs, ... }:

with lib; {
  options.modules.hardware.audio = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.hardware.audio {
    sound.enable = true;

    hardware.pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
    };

    user.extraGroups = [ "audio" ];
  };
}
