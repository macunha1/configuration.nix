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
    hardware = {
      opengl = {
        enable = true;
        driSupport32Bit = true;
        extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
      };
      pulseaudio.support32Bit = config.modules.hardware.audio.enable;
      steam-hardware.enable =
        config.modules.desktop.gaming.steam.hardware.enable;
    };

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
        mimeType = "x-scheme-handler/steam";
        categories = "Network;FileTransfer;Game";
      })
    ];

    # better for steam proton games
    systemd.extraConfig = "DefaultLimitNOFILE=1048576";
  };
}
