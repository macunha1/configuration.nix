# modules/development --- root config for development modules

{ pkgs, ... }:
{
  imports = [
    ./java.nix
    ./lua.nix
    ./node.nix
    ./python.nix
    ./rust.nix
    ./go.nix
  ];

  options = {};
  config = {};
}
