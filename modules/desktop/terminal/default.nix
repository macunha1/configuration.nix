{ config, options, lib, pkgs, ... }:
with lib;
{
  imports = [
    ./alacritty.nix
  ];

  config = {
    my.env.TERMINAL = config.modules.editors.default;
  };
}
