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
