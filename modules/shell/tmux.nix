{ config, options, pkgs, lib, ... }:

with lib;
with lib.my; {
  options.modules.shell.tmux = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.tmux.enable {
    user.packages = with pkgs;
      [
        # Since Tmux doesn't support XDG spec, we force it with a wrapper
        (writeScriptBin "tmux" ''
          #!${stdenv.shell}
          exec ${tmux}/bin/tmux -f "$TMUX_HOME/tmux.conf" "$@"
        '')
      ];

    environment.shellAliases = { t = "tmux"; };

    env.TMUX_HOME = "$XDG_CONFIG_HOME/tmux";
    env.TMUX_PLUGIN_MANAGER_PATH = "$XDG_CONFIG_HOME/tmux/plugins";

    # Following path from https://github.com/tmux-plugins/tpm
    home.configFile."tmux/tmux.conf" = {
      source = "${configDir}/tmux/tmux.conf";
    };

    home.configFile."tmux/plugins/tpm" = {
      source = pkgs.fetchFromGitHub {
        owner = "tmux-plugins";
        repo = "tpm";
        rev = "v3.0.0";
        sha256 = "18q5j92fzmxwg8g9mzgdi5klfzcz0z01gr8q2y9hi4h4n864r059";
      };
    };
  };
}
