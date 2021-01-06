{ config, lib, pkgs, ... }:

{
  user.packages = with pkgs; [
    pcmanfm # lightweight file manager
    xfce.xfce4panel # system trail

    # Screenshooters
    scrot # Lightweight screenshooter
    xfce.xfce4-screenshooter

    feh # Simple image viewer
    xclip # clipboard access from terminal
  ];

  ## Fonts
  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;

    fonts = with pkgs; [ powerline-fonts source-code-pro ];
    fontconfig.defaultFonts.monospace = [ "Source Code Pro" ];
  };
}
