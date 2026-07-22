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

  inherit (lib.my or (import ../../../lib/modules.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  xdg = (lib.my or (import ../../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

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
      default = xdg.concrete.config "codegraphcontext";
      description = "CodeGraphContext configuration directory.";
    };

    dataHome = mkOption {
      type = with types; either str path;
      default = xdg.concrete.data "codegraphcontext";
      description = "CodeGraphContext data directory.";
    };

    cacheHome = mkOption {
      type = with types; either str path;
      default = xdg.concrete.cache "codegraphcontext";
      description = "CodeGraphContext cache directory.";
    };
  };

  config = mkIf config.modules.agents.mcp.codegraphcontext.enable (mkMerge [
    {
      modules.development.python.enable = true;
    }

    (platformPackages {
      inherit isDarwin;
      packages = codegraphcontextPackages;
    })

    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = codegraphcontextEnvVars;
      darwinTarget = "both";
    })
  ]);
}
