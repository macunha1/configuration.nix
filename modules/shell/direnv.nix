# shell/direnv.nix -- https://github.com/direnv/direnv
#
# Path relative configurations for repositories and tools. Extends greatly some
# version managers for projects and fits perfectly with lorri for NixOS.
#
# direnv allows to have configurations such as "enable the Python virtual env"
# inside the repository path and unload when you leave it.

{ config, options, lib, pkgs, ... }:

with lib; {
  options.modules.shell.direnv = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.direnv.enable {
    user.packages = [ pkgs.direnv ];
    modules.shell.zsh.init = ''eval "$(direnv hook zsh)"'';

    services.lorri.enable = true;
  };
}
