{ config, lib, pkgs, ... }:

{
  imports = [
    ./awesomewm.nix
    ./applications
    ./browsers

    ./common.nix
    ./terminal
  ];
}
