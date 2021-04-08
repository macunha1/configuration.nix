# development/clisp.nix -- https://lisp-lang.org/
#
# The language in which the gods wrote the Universe.
# Ref: https://www.gnu.org/fun/jokes/eternal-flame.en.html

{ config, options, lib, pkgs, ... }:

with lib; {
  options.modules.development.clisp = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.clisp.enable {
    user.packages = with pkgs; [ sbcl lispPackages.quicklisp ];
  };
}
