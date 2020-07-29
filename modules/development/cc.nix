# modules/development/cc.nix --- C & C++

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.development.cc = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.cc.enable {
    my.packages = with pkgs; [
      clang
      gcc
      gdb

      cmake
      llvmPackages.libcxx
    ];
  };
}
