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
      contextModePlatform,
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
          CONTEXT_MODE_DIR = config.modules.agents.plugins.context-mode.storageHome;
          CONTEXT_MODE_DATA_DIR = builtins.dirOf (
            toString config.modules.agents.plugins.context-mode.storageHome
          );
          CONTEXT_MODE_PLATFORM = contextModePlatform;
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
        env = config.modules.agents.mcp.codegraphcontext.environment;
      }
    ];
}
