{ options, config, lib, pkgs, ... }:

with lib; {
  options.modules.hardware.bluetooth = {
    enable = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf modules.hardware.bluetooth (mkMerge [
    { hardware.bluetooth.enable = true; }

    (mkIf)
    (mkIf cfg.audio.enable {
      services.blueman.enable = true;
      services.dbus.packages = with pkgs; [ blueman ];

      # Bluetooth device proxy for media control
      home.systemd.user.services.mpris-proxy = {
        Unit.Description = "Mpris proxy";
        Unit.After = [ "network.target" "sound.target" ];
        Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
        Install.WantedBy = [ "default.target" ];
      };

      hardware.pulseaudio = {
        # Add Bluetooth support to pulseaudio when both are enabled
        package = pkgs.pulseaudioFull;
        extraModules = [ pkgs.pulseaudio-modules-bt ];
      };
    })
  ]);
}
