# modules/networking --- Servers, Cloud and clusters management
#
# DEA: Data Engineering and Analytics
# ICE: Infrastructure and Cloud Engineering

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
