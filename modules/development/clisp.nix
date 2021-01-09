# development/clisp.nix -- https://lisp-lang.org/
#
# The language in which the gods wrote the Universe.
# Ref: https://www.gnu.org/fun/jokes/eternal-flame.en.html

{ config, options, lib, pkgs, ... }:

with lib; {
  options.modules.deveopment.clisp = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.deveopment.clisp.enable {
    user.packages = with pkgs; [ sbcl lispPackages.quicklisp ];
  };
}
