# modules/development/node.nix --- https://nodejs.org/en/

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.development.node = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.node.enable {
    my = {
      packages = with pkgs; [
        nodejs
        yarn
      ];

      env.NPM_CONFIG_USERCONFIG = "$XDG_CONFIG_HOME/npm/config";
      env.NPM_CONFIG_CACHE      = "$XDG_CACHE_DIR/npm";
      env.NPM_CONFIG_TMP        = "$XDG_RUNTIME_DIR/npm";
      env.NPM_CONFIG_PREFIX     = "$XDG_CACHE_DIR/npm";
      env.NODE_REPL_HISTORY     = "$XDG_CACHE_DIR/node/repl_history";
      env.PATH = [ "$(yarn global bin)" ];

      # Run locally installed bin-script, e.g. n coffee file.coffee
      alias.n  = "PATH=\"$(npm bin):$PATH\"";
      alias.ya = "yarn";

      # TODO: Set the cache value to store in /data/1/...
      # home.xdg.configFile."npm/config".text = ''
      #   cache=$XDG_CACHE_DIR/npm
      #   prefix=$XDG_DATA_DIR/npm
      # '';
    };
  };
}
