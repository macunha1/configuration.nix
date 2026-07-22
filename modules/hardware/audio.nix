# hardware/audio.nix -- https://pipewire.org/
#
# PipeWire audio stack for Linux. PipeWire provides PulseAudio compatibility
# through services.pipewire.pulse.

{
  options,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
{
  options.modules.hardware.audio = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    support32Bit.enable = mkOption {
      type = types.bool;
      default = false;

      description = "Whether or not to enable support for 32-bit libraries on 64-bit systems";
    };
  };

  config = mkIf config.modules.hardware.audio.enable (mkMerge [
    {
      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = config.modules.hardware.audio.support32Bit.enable;
        };
        pulse.enable = true;
      };

      user.extraGroups = [ "audio" ];
    }

    (mkIf config.modules.desktop.enable {
      environment.systemPackages = with pkgs; [
        # PulseAudio Volume Control GUI
        pavucontrol
      ];
    })
  ]);
}
