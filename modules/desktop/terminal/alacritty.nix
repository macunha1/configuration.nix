{ config, lib, pkgs, ... }:

with lib; {
  options.modules.desktop.terminal.alacritty = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.terminal.alacritty.enable (mkMerge [
    {
      packages = with pkgs;
        [
          alacritty # GPU-accelerated terminal
        ];
    }

    (mkIf config.modules.shell.zsh.enable {
      # workaround for TERM=alacritty issues with Vim and Tmux
      zsh.rc = ''[[ "$TERM" = "alacritty" ]] && export TERM=xterm-256color'';
    })

    (mkIf pkgs.stdenv.isDarwin {
      home.configFile."alacritty/alacritty.yml" = {
        source = <config/alacritty/macos.yaml>;
      };
    })

    (mkIf pkgs.stdenv.isLinux {
      home.configFile."alacritty/alacritty.yml" = {
        source = <config/alacritty/linux.yaml>;
      };
    })
  ]);
}
