{ config, lib, pkgs, ... }:

{
  imports = [
    ./calibre.nix
    ./docker.nix
    ./kvm2.nix
    ./nvidia.nix
  ];
}
