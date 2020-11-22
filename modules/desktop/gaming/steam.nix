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
    # I avoid programs.steam.enable because it installs another steam binary,
    # which the xdesktop package invokes, instead of my steam shims below.
    hardware = {
      opengl = {
        enable = true;
        driSupport32Bit = true;
        extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
      };
      # Ideally: hardware.pulseaudio.support32Bit = config.hardware.pulseaudio.enable;
      pulseaudio.support32Bit = true;
      steam-hardware.enable =
        config.modules.desktop.gaming.steam.hardware.enable;
    };

    my.packages = with pkgs; [
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
