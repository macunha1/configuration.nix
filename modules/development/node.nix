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
        env.NPM_CONFIG_CACHE = "$XDG_CACHE_DIR/npm";
        env.NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
        env.NPM_CONFIG_PREFIX = "$XDG_CACHE_DIR/npm";
        env.NODE_REPL_HISTORY = "$XDG_CACHE_DIR/node/repl_history";

        # Ref https://yarnpkg.com/configuration/yarnrc
        env.YARN_CACHE_FOLDER = "$XDG_CACHE_DIR/node/yarn";
        env.YARN_RC_FILENAME = "$XDG_CONFIG_DIR/node/yarnrc";

        home.xdg.configFile."npm/config".text = ''
          cache=$XDG_CACHE_DIR/npm
          prefix=$XDG_DATA_DIR/npm
        '';
      }

      (mkIf config.modules.development.node.includeBinToPath {
        env.PATH = [ "$(yarn global bin)" ];
      })
    ];
  };
}
