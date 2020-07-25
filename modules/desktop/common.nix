{ config, lib, pkgs, ... }:

{
  my.packages = with pkgs; [
    pcmanfm    # lightweight file manager
    xfce.xfce4panel # system trail

    # Screenshooters
    scrot
    xfce.xfce4-screenshooter

    calibre # ebooks manager
    feh     # image viewer
    mpv     # video player
    xclip   # clipboard access from terminal
  ];

  ## Sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  ## Fonts
  fonts = {
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      powerline-fonts
      source-code-pro
    ];

    fontconfig.defaultFonts = {
      monospace = ["Source Code Pro"];
    };
  };
}
