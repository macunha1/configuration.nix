# desktop/terminal/alacritty.nix -- https://github.com/alacritty/alacritty
#
# The powerful GPU-accelerated terminal fully written in Rust. Flawless!

{
  options,
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

with lib;
with lib.my;
{
  options.modules.desktop.terminal.alacritty = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.terminal.alacritty.enable (mkMerge [
    {
      user.packages = with pkgs; [ alacritty ];

      # workaround for TERM=alacritty issues with Vim and Tmux
      modules.shell.zsh.init = ''[[ "$TERM" = "alacritty" ]] && export TERM=xterm-256color'';
    }

    (optionalAttrs isDarwin {
      home.configFile."alacritty/alacritty.yml" = {
        source = "${configDir}/alacritty/macos.yaml";
      };
    })

    (mkIf pkgs.stdenv.isLinux {
      home.configFile."alacritty/alacritty.yml" = {
        source = "${configDir}/alacritty/linux.yaml";
      };
    })
  ]);
}
