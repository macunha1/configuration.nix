# shell/direnv.nix -- https://github.com/direnv/direnv
#
# Path-relative configurations for repositories and tools. Extends greatly some
# version managers for projects and fits perfectly with lorri for NixOS.
#
# direnv allows to have configurations such as "enable the Python virtual env"
# inside the repository path and unload when you leave it.
#
# Linux: direnv installed as a user package; zsh hook appended to init.zsh.
# Darwin: programs.direnv managed declaratively by home-manager (includes nix-direnv).

{ config, options, lib, pkgs, isDarwin ? pkgs.stdenv.isDarwin, ... }:

with lib; {
  options.modules.shell.direnv = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.direnv.enable (mkMerge [

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = [ pkgs.direnv ];
      modules.shell.zsh.init = ''eval "$(direnv hook zsh)"'';
    })

    # Darwin (MacOS)
    # nix-direnv speeds up nix-shell / flake devShell entry.
    (optionalAttrs isDarwin {
      programs.direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };
    })
  ]);
}
