{ config, lib, pkgs, ... }:

{
  imports = [
    ./calibre.nix
    ./uhk-agent.nix
    ./redshift.nix
    ./rofi.nix
  ];
}
