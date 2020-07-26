{ config, lib, pkgs, ... }:

{
  imports = [
    ./uhk-agent.nix
    ./redshift.nix
  ];
}
