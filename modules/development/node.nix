# development/node.nix -- https://nodejs.org/en/
#
# JavaScript everywhere. The V8 runtime that escaped the browser.
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

  inherit (lib.my or (import ../../lib/modules.nix { inherit lib; }))
    platformEnv
    platformPackages
    platformPath
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  nodeRuntimePackages = with pkgs; [
    nodejs # JavaScript runtime
  ];

  bunPackages = with pkgs; [
    bun # JavaScript runtime, package manager, bundler, and test runner
  ];

  # XDG-compliant npm paths - same values on both platforms.
  nodeEnvVars = {
    NPM_CONFIG_USERCONFIG = xdg.shell.config "npm/config";
    NPM_CONFIG_CACHE = xdg.shell.cache "npm/cache";
    NPM_CONFIG_PREFIX = xdg.shell.data "npm"; # global install target
    NODE_REPL_HISTORY = xdg.shell.config "node/repl_history";
  };

  # XDG-compliant Bun paths - same values on both platforms.
  bunEnvVars = {
    BUN_INSTALL = xdg.shell.data "bun";
    BUN_INSTALL_GLOBAL_DIR = xdg.shell.data "bun/install/global";
    BUN_INSTALL_BIN = xdg.shell.data "bun/bin";
    BUN_INSTALL_CACHE_DIR = xdg.shell.cache "bun/install/cache";
  };

  # npm config file - same content on both platforms; only the option differs.
  npmConfigText = ''
    ${generatedFileWarning { file = ./node.nix; }}
    cache=''${XDG_CACHE_HOME}/npm/cache
    prefix=''${XDG_DATA_HOME}/npm
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
      (platformPackages {
        inherit isDarwin;
        packages = nodeRuntimePackages;
      })

      (platformEnv {
        inherit config isDarwin;
        inherit shellExports;
        envVars = nodeEnvVars;
        target = "zsh";
      })

      (optionalAttrs (!isDarwin) {
        home.configFile."npm/config".text = npmConfigText;
      })

      (optionalAttrs isDarwin {
        xdg.configFile."npm/config".text = npmConfigText;
      })
    ]))

    (mkIf config.modules.development.node.languageServer.enable (platformPackages {
      inherit isDarwin;
      packages = with pkgs; [ javascript-typescript-langserver ];
    }))

    (mkIf
      (
        config.modules.development.node.enable
        && config.modules.development.node.includeBinToPath
        && config.modules.development.node.bun.enable
      )
      (platformPath {
        inherit config isDarwin;
        paths = [ (xdg.concrete.data "bun/bin") ];
        target = "both";
      })
    )

    (mkIf (config.modules.development.node.enable && config.modules.development.node.bun.enable)
      (mkMerge [
        (platformPackages {
          inherit isDarwin;
          packages = bunPackages;
        })

        (platformEnv {
          inherit config isDarwin;
          inherit shellExports;
          envVars = bunEnvVars;
          target = "zsh";
        })
      ])
    )
  ];
}
