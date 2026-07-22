# development/clisp.nix -- https://lisp-lang.org/
#
# The language in which the gods wrote the Universe.
# Ref: https://www.gnu.org/fun/jokes/eternal-flame.en.html
#
# Linux: installed as user packages.
# Darwin: installed as home packages.

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

  clispPackages = with pkgs; [
    sbcl # Steel Bank Common Lisp — fast, conforming ANSI CL
    lispPackages.quicklisp # package manager for Common Lisp
  ];
in
{
  options.modules.development.clisp = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.clisp.enable (mkMerge [
    (platformPackages {
      inherit isDarwin;
      packages = clispPackages;
    })
  ]);
}
