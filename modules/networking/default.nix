# modules/networking --- Servers, Cloud and clusters management

{ pkgs, ... }:
{
  imports = [
    ./terraform.nix
    ./kubernetes.nix
    ./aws.nix
    ./gcp.nix
  ];

  options = {};
  config = {};
}
