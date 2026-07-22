# agents/plugins/context-mode.nix -- https://github.com/mksglu/context-mode
#
# Context-window optimization plugin and MCP server for coding agents.
#
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
  inherit (lib.my or (import ../../../lib/generators.nix { inherit lib pkgs; }))
    shellExports
    ;

  inherit (lib.my or (import ../../../lib/modules.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  xdg = (lib.my or (import ../../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  contextModePackage = pkgs.writeShellApplication {
    name = "context-mode";
    runtimeInputs = [
      pkgs.nodejs
    ];
    text = ''
      exec npm exec --yes context-mode -- "$@"
    '';
  };

  contextModePackages = [
    pkgs.nodejs
    contextModePackage
  ];

  contextModeEnvVars = {
    CONTEXT_MODE_CONFIG_HOME = config.modules.agents.plugins.context-mode.configHome;
    CONTEXT_MODE_DATA_HOME = config.modules.agents.plugins.context-mode.dataHome;
    CONTEXT_MODE_CACHE_HOME = config.modules.agents.plugins.context-mode.cacheHome;
  };
in
{
  options.modules.agents.plugins.context-mode = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    configHome = mkOption {
      type = with types; either str path;
      default = xdg.concrete.config "context-mode";
      description = "Context Mode configuration directory.";
    };

    dataHome = mkOption {
      type = with types; either str path;
      default = xdg.concrete.data "context-mode";
      description = "Context Mode data directory.";
    };

    cacheHome = mkOption {
      type = with types; either str path;
      default = xdg.concrete.cache "context-mode";
      description = "Context Mode cache directory.";
    };
  };

  config = mkIf config.modules.agents.plugins.context-mode.enable (mkMerge [
    {
      modules.development.python.enable = true;
    }

    (platformPackages {
      inherit isDarwin;
      packages = contextModePackages;
    })

    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = contextModeEnvVars;
      darwinTarget = "both";
    })
  ]);
}
