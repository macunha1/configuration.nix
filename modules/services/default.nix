{ config, lib, pkgs, ... }:

{
  imports = [
    ./docker.nix
    ./kvm2.nix
  ];
}
