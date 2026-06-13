# development/clisp.nix -- https://lisp-lang.org/
#
# The language in which the gods wrote the Universe.
# Ref: https://www.gnu.org/fun/jokes/eternal-flame.en.html
#
# Linux: installed as user packages.
# Darwin: installed as home packages.

{ config, options, lib, pkgs, isDarwin ? pkgs.stdenv.isDarwin, ... }:

with lib;

let
  clispPackages = with pkgs; [
    sbcl               # Steel Bank Common Lisp — fast, conforming ANSI CL
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

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = clispPackages;
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      home.packages = clispPackages;
    })
  ]);
}
