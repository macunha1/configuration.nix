# development/node.nix -- https://nodejs.org/en/
#
# JavaScript everywhere. The V8 runtime that escaped the browser.
#
# Linux: user.packages + env = nodeEnvVars + home.configFile."npm/config".
# Darwin: home.packages + modules.shell.zsh.env = nodeEnvVars + xdg.configFile."npm/config".

{
  config,
  options,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

with lib;

let
  # Some standalone evaluations pass plain nixpkgs.lib, so lib.my may be absent.
  # Import the generator directly in that case.
  inherit (lib.my or (import ../../lib/generators.nix { inherit lib pkgs; }))
    generatedFileWarning
    ;

  nodePackages = with pkgs; [
    nodejs # JavaScript runtime
    yarn # faster, deterministic package manager
  ];

  # XDG-compliant npm/yarn paths - same values on both platforms.
  nodeEnvVars = {
    NPM_CONFIG_USERCONFIG = "$XDG_CONFIG_HOME/npm/config";
    NPM_CONFIG_CACHE = "$XDG_CACHE_HOME/npm/cache";
    NPM_CONFIG_TMP = "$XDG_CACHE_HOME/npm/temp";
    NPM_CONFIG_PREFIX = "$XDG_DATA_HOME/npm"; # global install target
    NODE_REPL_HISTORY = "$XDG_CONFIG_HOME/node/repl_history";
    # Ref https://yarnpkg.com/configuration/yarnrc
    YARN_CACHE_FOLDER = "$XDG_CACHE_HOME/node/yarn";
    YARN_RC_FILENAME = "$XDG_CONFIG_HOME/node/yarnrc";
  };

  # npm config file - same content on both platforms; only the option differs.
  npmConfigText = ''
    ${generatedFileWarning { file = ./node.nix; }}
    cache=$XDG_CACHE_HOME/npm/cache
    prefix=$XDG_DATA_HOME/npm
  '';
in
{
  options.modules.development.node = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    languageServer = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };

    includeBinToPath = mkOption {
      type = types.bool;
      default = false;
    };

    bun = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkMerge [
    (mkIf config.modules.development.node.enable (mkMerge [

      # Linux (NixOS)
      (optionalAttrs (!isDarwin) {
        user.packages = nodePackages;
        env = nodeEnvVars;
        home.configFile."npm/config".text = npmConfigText;
      })

      # Darwin (MacOS)
      (optionalAttrs isDarwin {
        home.packages = nodePackages;
        modules.shell.zsh.env = ''
          export NPM_CONFIG_USERCONFIG="${config.xdg.configHome}/npm/config"
          export NPM_CONFIG_CACHE="${config.xdg.cacheHome}/npm/cache"
          export NPM_CONFIG_TMP="${config.xdg.cacheHome}/npm/temp"
          export NPM_CONFIG_PREFIX="${config.xdg.dataHome}/npm"
          export NODE_REPL_HISTORY="${config.xdg.configHome}/node/repl_history"
          export YARN_CACHE_FOLDER="${config.xdg.cacheHome}/node/yarn"
          export YARN_RC_FILENAME="${config.xdg.configHome}/node/yarnrc"
        '';
        xdg.configFile."npm/config".text = npmConfigText;
      })
    ]))

    (mkIf config.modules.development.node.languageServer.enable (mkMerge [
      (optionalAttrs (!isDarwin) {
        user.packages = with pkgs; [ nodePackages.javascript-typescript-langserver ];
      })
      (optionalAttrs isDarwin {
        home.packages = with pkgs; [ nodePackages.javascript-typescript-langserver ];
      })
    ]))

    (mkIf config.modules.development.node.includeBinToPath (mkMerge [
      (optionalAttrs (!isDarwin) {
        env.PATH = [ "$(yarn global bin)" ];
      })
      (optionalAttrs isDarwin {
        modules.shell.zsh.env = ''
          export PATH="$(yarn global bin):$PATH"
        '';
      })
    ]))

    (mkIf config.modules.development.node.bun.enable (mkMerge [
      # Linux (NixOS)
      (optionalAttrs (!isDarwin) {
        user.packages = with pkgs; [ bun ];
        env.BUN_INSTALL = "$XDG_DATA_HOME/bun";
        env.PATH = [ "$XDG_DATA_HOME/bun/bin" ];
      })

      # Darwin (MacOS)
      (optionalAttrs isDarwin {
        home.packages = with pkgs; [ bun ];
        modules.shell.zsh.env = ''
          export BUN_INSTALL="${config.xdg.dataHome}/bun"
          export PATH="${config.xdg.dataHome}/bun/bin:$PATH"
        '';
      })
    ]))
  ];
}
