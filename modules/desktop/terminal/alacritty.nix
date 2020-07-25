{ config, lib, pkgs, ... }:

with lib;
{
  options.modules.desktop.term.alacritty = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.term.alacritty.enable {
    # workaroung TERM=alacritty issues with Vim and Tmux
    my.zsh.rc = ''[[ "$TERM" = "alacritty" ]] && export TERM=xterm-256color'';

    my.packages = with pkgs; [
      alacritty # GPU-accelerated terminal
    ];
  };
}
