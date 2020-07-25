# modules/dev --- common settings for dev modules

{ pkgs, ... }:
{
  imports = [
    ./java.nix
    ./lua.nix
    ./node.nix
    ./python.nix
    ./rust.nix
    # ./go.nix # TODO
  ];

  options = {};
  config = {};
}
