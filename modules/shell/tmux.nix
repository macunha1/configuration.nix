{ config, options, pkgs, lib, ... }:

with lib;
{
  options.modules.shell.tmux = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.tmux.enable {
    my = {
      packages = with pkgs; [
        # The developer of tmux chooses not to add XDG support for religious
        # reasons (see tmux/tmux#142). Nix to the rescue
        (writeScriptBin "tmux" ''
          #!${stdenv.shell}
          exec ${tmux}/bin/tmux -f "$TMUX_HOME/tmux.conf" "$@"
          '')
      ];

      zsh.rc = ''
        alias t=tmux
      '';

      # Environment values currently managed through .profiles.d from .zprofile
      # env.TMUX_HOME = "$XDG_CONFIG_HOME/tmux";
      # env.TMUX_PLUGIN_MANAGER_PATH = "$XDG_DATA_HOME/tmux/plugins"

      # Following path from https://github.com/tmux-plugins/tpm
      home.xdg.configFile."tmux/tmux.conf" = {
        source = <config/tmux/tmux.conf>;
      };

      home.xdg.configFile."tmux/plugins/tpm" = {
        source = builtins.fetchGit {
          url = "https://github.com/tmux-plugins/tpm";
          ref = "tags/v3.0.0";
          rev = "234002ad1c58e04b4e74853c7f1698874f69da60";
        };
      };
    };
  };
}
