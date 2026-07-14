# agents/mcp/codegraphcontext.nix -- https://github.com/macunha1/CodeGraphContext
#
# Code graph indexing CLI and MCP server.
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

  codegraphcontextPackage = pkgs.writeShellApplication {
    name = "codegraphcontext";

    text = ''
      exec ${config.modules.development.python.packageManagerCommand} tool \
        run --from "${config.modules.agents.mcp.codegraphcontext.source}" \
        codegraphcontext "$@"
    '';
  };

  cgcPackage = pkgs.writeShellApplication {
    name = "cgc";

    text = ''
      exec ${config.modules.development.python.packageManagerCommand} tool \
        run --from "${config.modules.agents.mcp.codegraphcontext.source}" \
        cgc "$@"
    '';
  };

  codegraphcontextPackages = [
    codegraphcontextPackage
    cgcPackage
  ];

  codegraphcontextEnvVars = {
    DEFAULT_DATABASE = "falkordb";
    CGC_CONFIG_DIR = config.modules.agents.mcp.codegraphcontext.configHome;
    CGC_DATA_DIR = config.modules.agents.mcp.codegraphcontext.dataHome;
    CGC_CACHE_DIR = config.modules.agents.mcp.codegraphcontext.cacheHome;
    FALKORDB_PATH = "${config.modules.agents.mcp.codegraphcontext.dataHome}/global/db/falkordb";
    FALKORDB_SOCKET_PATH = "${config.modules.agents.mcp.codegraphcontext.dataHome}/global/db/falkordb.sock";
    LOG_FILE_PATH = "${config.modules.agents.mcp.codegraphcontext.cacheHome}/logs/cgc.log";
    DEBUG_LOG_PATH = "${config.modules.agents.mcp.codegraphcontext.cacheHome}/logs/debug.log";
  };
in
{
  options.modules.agents.mcp.codegraphcontext = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    source = mkOption {
      type = types.str;
      default = "git+https://github.com/macunha1/CodeGraphContext";
      description = "Python package source for the CodeGraphContext fork.";
    };

    configHome = mkOption {
      type = with types; either str path;
      default =
        if isDarwin then
          "${config.xdg.configHome}/codegraphcontext"
        else
          "$XDG_CONFIG_HOME/codegraphcontext";
      description = "CodeGraphContext configuration directory.";
    };

    dataHome = mkOption {
      type = with types; either str path;
      default =
        if isDarwin then "${config.xdg.dataHome}/codegraphcontext" else "$XDG_DATA_HOME/codegraphcontext";
      description = "CodeGraphContext data directory.";
    };

    cacheHome = mkOption {
      type = with types; either str path;
      default =
        if isDarwin then "${config.xdg.cacheHome}/codegraphcontext" else "$XDG_CACHE_HOME/codegraphcontext";
      description = "CodeGraphContext cache directory.";
    };
  };

  config = mkIf config.modules.agents.mcp.codegraphcontext.enable (mkMerge [
    {
      modules.development.python.enable = true;
    }

    (mkIf config.modules.shell.zsh.enable {
      modules.shell.zsh.env = shellExports codegraphcontextEnvVars;
    })

    (optionalAttrs (!isDarwin) {
      user.packages = codegraphcontextPackages;
      env = codegraphcontextEnvVars;
    })

    (optionalAttrs isDarwin {
      home.packages = codegraphcontextPackages;
      home.sessionVariables = codegraphcontextEnvVars;
    })
  ]);
}
