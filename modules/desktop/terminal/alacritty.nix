# desktop/terminal/alacritty.nix -- https://github.com/alacritty/alacritty
#
# The powerful GPU-accelerated terminal fully written in Rust. Flawless!

{
  options,
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
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

    font = {
      family = mkOption {
        type = types.str;
        default = "Source Code Pro";
        description = "Alacritty font family for this host.";
      };

      size = mkOption {
        type = types.float;
        default = 12.0;
        description = "Alacritty font size for this host.";
      };
    };
  };

  config = mkIf config.modules.desktop.terminal.alacritty.enable (mkMerge [
    {
      fonts.packages = [ pkgs.source-code-pro ];
      user.packages = with pkgs; [ alacritty ];

      # workaround for TERM=alacritty issues with Vim and Tmux
      modules.shell.zsh.init = ''[[ "$TERM" = "alacritty" ]] && export TERM=xterm-256color'';
    }

    {
      # Alacritty fills omitted settings from its built-in defaults. Keep one
      # current-format file shared by Linux and macOS.
      home.configFile."alacritty/alacritty.toml" = {
        text =
          replaceStrings
            [
              "{font.size}"
              "{font.family}"
            ]
            [
              (toString config.modules.desktop.terminal.alacritty.font.size)
              (builtins.toJSON config.modules.desktop.terminal.alacritty.font.family)
            ]
            (builtins.readFile "${configDir}/alacritty/alacritty.toml");
        force = true;
      };
    }
  ]);
}
