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
          exec ${tmux}/bin/tmux -f "$TMUX_HOME/config" "$@"
          '')
      ];

      env.TMUX_HOME = "$XDG_CONFIG_HOME/tmux";

      zsh.rc = ''
        alias t=tmux
      '';

      # TODO: Currently managing plugins via TPM, change to NixOS config
      # home.xdg.configFile = {
      #   "tmux" = { source = <config/tmux>; recursive = true; };
      #   "tmux/plugins".text = '' '';
      # };
    };
  };
}
