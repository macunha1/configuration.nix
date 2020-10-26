# modules/development --- root config for development modules

{ pkgs, ... }: {
  imports = [
    ./cc.nix
    ./go.nix
    ./java.nix
    ./lua.nix
    ./node.nix
    ./python.nix
    ./ruby.nix
    ./rust.nix
  ];

  options = { };
  config = { };
}
