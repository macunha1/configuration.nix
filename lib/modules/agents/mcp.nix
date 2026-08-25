{ lib, ... }:

let
  inherit (lib) optionals;
in
{
  managedMcpServerNames = [
    "mempalace"
    "context-mode"
    "CodeGraphContext"
  ];

  mkMcpServers =
    {
      config,
      profileDirectory,
    }:
    optionals config.modules.agents.mcp.mempalace.enable [
      {
        name = "mempalace";
        command = "${profileDirectory}/bin/mempalace-mcp";
        env = {
          MEMPALACE_PALACE_PATH = config.modules.agents.mcp.mempalace.palacePath;
        };
      }
    ]
    ++ optionals config.modules.agents.plugins.context-mode.enable [
      {
        name = "context-mode";
        command = "${profileDirectory}/bin/context-mode";
        env = {
          CONTEXT_MODE_CONFIG_HOME = config.modules.agents.plugins.context-mode.configHome;
          CONTEXT_MODE_DATA_HOME = config.modules.agents.plugins.context-mode.dataHome;
          CONTEXT_MODE_CACHE_HOME = config.modules.agents.plugins.context-mode.cacheHome;
        };
      }
    ]
    ++ optionals config.modules.agents.mcp.codegraphcontext.enable [
      {
        name = "CodeGraphContext";
        command = "${profileDirectory}/bin/codegraphcontext";
        args = [
          "mcp"
          "start"
        ];
        env = {
          DEFAULT_DATABASE = "falkordb";
          CGC_CONFIG_DIR = config.modules.agents.mcp.codegraphcontext.configHome;
          CGC_DATA_DIR = config.modules.agents.mcp.codegraphcontext.dataHome;
          CGC_CACHE_DIR = config.modules.agents.mcp.codegraphcontext.cacheHome;
          FALKORDB_PATH = "${config.modules.agents.mcp.codegraphcontext.dataHome}/global/db/falkordb";
          FALKORDB_SOCKET_PATH = "${config.modules.agents.mcp.codegraphcontext.dataHome}/global/db/falkordb.sock";
          LOG_FILE_PATH = "${config.modules.agents.mcp.codegraphcontext.cacheHome}/logs/cgc.log";
          DEBUG_LOG_PATH = "${config.modules.agents.mcp.codegraphcontext.cacheHome}/logs/debug.log";
        };
      }
    ];
}
