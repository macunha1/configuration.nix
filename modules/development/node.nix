# modules/development/node.nix --- https://nodejs.org/en/

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.development.node = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    includeBinToPath = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.node.enable {
    my = mkMerge [
      {
        packages = with pkgs; [ unstable.nodejs-14_x yarn ];

        env.NPM_CONFIG_USERCONFIG = "$XDG_CONFIG_HOME/npm/config";
        env.NPM_CONFIG_CACHE = "$XDG_CACHE_HOME/npm/cache";
        env.NPM_CONFIG_TMP = "$XDG_CACHE_HOME/npm/temp";
        env.NPM_CONFIG_PREFIX = "$XDG_DATA_HOME/npm";
        env.NODE_REPL_HISTORY = "$XDG_CONFIG_HOME/node/repl_history";

        # Ref https://yarnpkg.com/configuration/yarnrc
        env.YARN_CACHE_FOLDER = "$XDG_CACHE_HOME/node/yarn";
        env.YARN_RC_FILENAME = "$XDG_CONFIG_HOME/node/yarnrc";

        home.xdg.configFile."npm/config".text = ''
          cache=$XDG_CACHE_HOME/npm/cache
          prefix=$XDG_DATA_HOME/npm
        '';
      }

      (mkIf config.modules.development.node.includeBinToPath {
        env.PATH = [ "$(yarn global bin)" ];
      })
    ];
  };
}
