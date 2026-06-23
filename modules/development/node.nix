# development/node.nix -- https://nodejs.org/en/
#
# JavaScript everywhere. The V8 runtime that escaped the browser.
#
# Linux: user.packages + env = nodeEnvVars + home.configFile."npm/config".
# Darwin: home.packages + modules.shell.zsh.env = nodeEnvVars + xdg.configFile."npm/config".
#
# Bun package-manager support is gated by modules.development.node.bun.enable.

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
    shellExports
    ;

  nodePackages = with pkgs; [
    nodejs # JavaScript runtime
  ];

  bunPackages = with pkgs; [
    bun # JavaScript runtime, package manager, bundler, and test runner
  ];

  # XDG-compliant npm paths - same values on both platforms.
  nodeEnvVars = {
    NPM_CONFIG_USERCONFIG = "$XDG_CONFIG_HOME/npm/config";
    NPM_CONFIG_CACHE = "$XDG_CACHE_HOME/npm/cache";
    NPM_CONFIG_TMP = "$XDG_CACHE_HOME/npm/temp";
    NPM_CONFIG_PREFIX = "$XDG_DATA_HOME/npm"; # global install target
    NODE_REPL_HISTORY = "$XDG_CONFIG_HOME/node/repl_history";
  };

  # XDG-compliant Bun paths - same values on both platforms.
  bunEnvVars = {
    BUN_INSTALL = "$XDG_DATA_HOME/bun";
    BUN_INSTALL_GLOBAL_DIR = "$XDG_DATA_HOME/bun/install/global";
    BUN_INSTALL_BIN = "$XDG_DATA_HOME/bun/bin";
  };

  # npm config file - same content on both platforms; only the option differs.
  npmConfigText = ''
    ${generatedFileWarning { file = ./node.nix; }}
    cache=$XDG_CACHE_HOME/npm/cache
    prefix=$XDG_DATA_HOME/npm
  '';

  # Bun global config - same content on both platforms; only the option differs.
  bunConfigText = ''
    ${generatedFileWarning { file = ./node.nix; }}
    [install]
    globalDir = "$XDG_DATA_HOME/bun/install/global"
    globalBinDir = "$XDG_DATA_HOME/bun/bin"

    [install.cache]
    dir = "$XDG_CACHE_HOME/bun/install/cache"
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
        default = true;
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
        modules.shell.zsh.env = shellExports nodeEnvVars;
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

    (mkIf
      (
        config.modules.development.node.enable
        && config.modules.development.node.includeBinToPath
        && config.modules.development.node.bun.enable
      )
      (mkMerge [
        (optionalAttrs (!isDarwin) {
          env.PATH = [ "$BUN_INSTALL_BIN" ];
        })
        (optionalAttrs isDarwin {
          modules.shell.zsh.env = ''
            export PATH="$BUN_INSTALL_BIN:$PATH"
          '';
        })
      ])
    )

    (mkIf (config.modules.development.node.enable && config.modules.development.node.bun.enable)
      (mkMerge [
        # Linux (NixOS)
        (optionalAttrs (!isDarwin) {
          user.packages = bunPackages;
          env = bunEnvVars;
          home.configFile.".bunfig.toml".text = bunConfigText;
        })

        # Darwin (MacOS)
        (optionalAttrs isDarwin {
          home.packages = bunPackages;
          modules.shell.zsh.env = shellExports bunEnvVars;
          xdg.configFile.".bunfig.toml".text = bunConfigText;
        })
      ])
    )
  ];
}
