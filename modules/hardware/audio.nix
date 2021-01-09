# hardware/audio.nix -- https://www.freedesktop.org/wiki/Software/PulseAudio/
#
# PulseAudio sound system for Linux. Categorized under the generic name of
# "audio.nix" since it is the standard.

{ options, config, lib, pkgs, ... }:

with lib; {
  options.modules.hardware.audio = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.hardware.audio.enable (mkMerge [
    {
      sound.enable = true;
      hardware.pulseaudio.enable = true;

      user.extraGroups = [ "audio" ];
    }

    (mkIf config.modules.desktop.enable {
      environment.systemPackages = with pkgs;
        [
          # PulseAudio Volume Control GUI
          pavucontrol
        ];
    })
  ]);
}
