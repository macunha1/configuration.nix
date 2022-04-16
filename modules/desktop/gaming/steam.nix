# desktop/gaming/steam.nix -- https://store.steampowered.com/
#
# Steam is constantly raising the bar in terms of Linux gaming. This module
# enables Steam + 32-bit libs and configures the Steam client with custom (XDG
# base dir spec) path

{ options, config, lib, pkgs, ... }:

with lib; {
  options.modules.desktop.gaming.steam = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    hardware.enable = mkOption {
      type = types.bool;
      default = false;
    };

    libDir = mkOption {
      type = types.str;
      default = "$XDG_DATA_HOME/steamlib";
    };
  };

  config = mkIf config.modules.desktop.gaming.steam.enable {
    # NOTE: config.modules.hardware corresponds to modules in this repository,
    # they are subject to config.modules.hardware.{audio,video}.enable BEFORE
    # evaluating the following. i.e.: video and audio MUST be enabled to install
    # the 32-bit packages.
    #
    # Enjoy the UNOBTRUSIVE BEAUTY of a FP language!
    modules.hardware = {
      video = {
        enable = trivial.warnIf (!config.modules.hardware.video.enable) ''
          Steam is enabled but the video module isn't. Nix won't install
              the required video libraries''
          config.modules.hardware.video.enable;

        support32Bit.enable = true;
        extra32BitPackages = with pkgs.pkgsi686Linux; [ libva ];
      };

      audio = {
        enable = trivial.warnIf (!config.modules.hardware.audio.enable) ''
          Steam is enabled but the audio module isn't. Nix won't install
              the required audio libraries''
          config.modules.hardware.audio.enable;

        support32Bit.enable = true;
      };
    };

    hardware.steam-hardware.enable =
      config.modules.desktop.gaming.steam.hardware.enable;

    user.packages = with pkgs; [
      steam
      steam-run-native

      # Creates a desktop entry
      (makeDesktopItem {
        name = "steam";
        desktopName = "Steam";
        icon = "steam";
        exec = "steam";
        terminal = "false";
        categories = [ "Network" "FileTransfer" "Game" ];
      })
    ];

    # When running Steam Windows games through Proton (Wine), the number of file
    # descriptors can go sky-high due to esync, each synchronization object will
    # create one eventfd descriptor, possibly reaching the limit of file
    # descriptors.
    #
    # Let's not wait for a mental breakdown and increase it already
    #
    # Ref: https://github.com/zfigura/wine/blob/esync/README.esync
    systemd.extraConfig = "DefaultLimitNOFILE=1048576";
  };
}
