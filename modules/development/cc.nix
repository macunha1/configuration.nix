# development/cc.nix -- http://gcc.gnu.org/
#
# C and C++ — the foundation everything else is built on.
#
# Linux: user.packages.
# Darwin: home.packages.
# languageServer: ccls appended via optionals to avoid mkIf-in-list antipattern.

{
  config,
  options,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

with lib;

let
  inherit (lib.my or (import ../../lib/modules.nix { inherit lib; }))
    platformPackages
    ;

  # Base C/C++ toolchain — same on both platforms.
  ccPackages = with pkgs; [
    clang # LLVM C/C++ compiler frontend
    gcc # GNU C/C++ compiler
    gdb # GNU debugger
    cmake # cross-platform build system
    llvmPackages.libcxx # LLVM C++ standard library
  ];
in
{
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
    (platformPackages {
      inherit isDarwin;
      packages = ccPackages;
    })

    (mkIf config.modules.development.cc.languageServer.enable (platformPackages {
      inherit isDarwin;
      packages = with pkgs; [ ccls ]; # C/C++/Objective-C language server
    }))
  ]);
}
