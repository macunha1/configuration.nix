# development/cc.nix -- http://gcc.gnu.org/

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.development.cc = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    languageServer = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf config.modules.development.cc.enable {
    user.packages = with pkgs; [
      clang
      gcc
      gdb

      (mkIf (config.modules.development.cc.languageServer.enable)
      # C/C++/Objective C Language Server
        ccls)

      cmake
      llvmPackages.libcxx
    ];
  };
}
