{ config, lib, pkgs, ... }:

{
  imports = [
    ./common.nix
    ./awesomewm.nix
    
    ./applications
    ./terminal
    ./browsers
  ];
}
