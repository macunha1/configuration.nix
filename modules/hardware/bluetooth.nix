# hardware/bluetooth.nix
#
# Enables bluetooth support for Linux mainly for extending audio support with
# bluetooth headsets/headphones. Therefore, most of the configurations here are
# focused into enabling audio-related features.

{ options, config, lib, pkgs, ... }:

with lib; {
  options.modules.hardware.bluetooth = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.hardware.bluetooth.enable (mkMerge [
    { hardware.bluetooth.enable = true; }

    (mkIf config.modules.hardware.audio.enable {
      services.blueman.enable = true;
      services.dbus.packages = with pkgs; [ blueman ];

      # Bluetooth device proxy for media control
      # home-manager.systemd.${config.user.name}.services.mpris-proxy = {
      #   Unit.Description = "Mpris proxy";
      #   Unit.After = [ "network.target" "sound.target" ];
      #   Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
      #   Install.WantedBy = [ "default.target" ];
      # };

      hardware.pulseaudio = {
        # Add Bluetooth support to pulseaudio when both are enabled
        package = pkgs.pulseaudioFull;
        extraModules = [ pkgs.pulseaudio-modules-bt ];
      };
    })
  ]);
}
