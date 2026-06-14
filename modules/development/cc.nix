# development/cc.nix -- http://gcc.gnu.org/
#
# C and C++ — the foundation everything else is built on.
#
# Linux: user.packages.
# Darwin: home.packages.
# languageServer: ccls appended via optionals to avoid mkIf-in-list antipattern.

{ config, options, lib, pkgs, isDarwin ? pkgs.stdenv.isDarwin, ... }:

with lib;

let
  # Base C/C++ toolchain — same on both platforms.
  ccPackages = with pkgs; [
    clang # LLVM C/C++ compiler frontend
    gcc # GNU C/C++ compiler
    gdb # GNU debugger
    cmake # cross-platform build system
    llvmPackages.libcxx # LLVM C++ standard library
  ];
in {
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

  config = mkIf config.modules.development.cc.enable (mkMerge [

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) (mkMerge [
      { user.packages = ccPackages; }

      (mkIf config.modules.development.cc.languageServer.enable {
        user.packages = with pkgs; [ ccls ]; # C/C++/Objective-C language server
      })
    ]))

    # Darwin (MacOS)
    (optionalAttrs isDarwin (mkMerge [
      { home.packages = ccPackages; }

      (mkIf config.modules.development.cc.languageServer.enable {
        home.packages = with pkgs; [ ccls ]; # C/C++/Objective-C language server
      })
    ]))
  ]);
}
