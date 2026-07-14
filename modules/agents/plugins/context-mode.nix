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
      default =
        if isDarwin then "${config.xdg.configHome}/context-mode" else "$XDG_CONFIG_HOME/context-mode";
      description = "Context Mode configuration directory.";
    };

    dataHome = mkOption {
      type = with types; either str path;
      default = if isDarwin then "${config.xdg.dataHome}/context-mode" else "$XDG_DATA_HOME/context-mode";
      description = "Context Mode data directory.";
    };

    cacheHome = mkOption {
      type = with types; either str path;
      default =
        if isDarwin then "${config.xdg.cacheHome}/context-mode" else "$XDG_CACHE_HOME/context-mode";
      description = "Context Mode cache directory.";
    };
  };

  config = mkIf config.modules.agents.plugins.context-mode.enable (mkMerge [
    {
      modules.development.python.enable = true;
    }

    (mkIf config.modules.shell.zsh.enable {
      modules.shell.zsh.env = shellExports contextModeEnvVars;
    })

    (optionalAttrs (!isDarwin) {
      user.packages = contextModePackages;
      env = contextModeEnvVars;
    })

    (optionalAttrs isDarwin {
      home.packages = contextModePackages;
      home.sessionVariables = contextModeEnvVars;
    })
  ]);
}
