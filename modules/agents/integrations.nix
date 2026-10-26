# agents/integrations.nix -- contribution contract for coding-agent integrations

{ lib, ... }:

with lib;

let
  commandHookType = types.submodule {
    options = {
      command = mkOption {
        type = types.str;
        description = "Command invoked by the agent hook.";
      };

      timeout = mkOption {
        type = types.ints.positive;
        description = "Hook timeout in seconds.";
      };

      type = mkOption {
        type = types.str;
        default = "command";
        description = "Hook implementation type.";
      };
    };
  };

  hookGroupType = types.submodule {
    options = {
      matcher = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional agent-specific hook matcher.";
      };

      hooks = mkOption {
        type = types.listOf commandHookType;
        description = "Commands invoked for this hook group.";
      };
    };
  };

  agentMcpServerType = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Expose this MCP server to the agent.";
      };

      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Agent-specific MCP server name override.";
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Environment merged into the MCP server for this agent.";
      };

      settings = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Agent-specific MCP server settings.";
      };
    };
  };

  mcpServerType = types.submodule {
    options = {
      command = mkOption {
        type = types.str;
        description = "Executable used to start the MCP server.";
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Arguments passed to the MCP server executable.";
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Environment shared by every agent using the MCP server.";
      };

      agents = mkOption {
        type = types.attrsOf agentMcpServerType;
        default = { };
        description = "Per-agent MCP name, environment, and settings overrides.";
      };
    };
  };
in
{
  options.modules.agents.integrations = {
    mcpServers = mkOption {
      type = types.attrsOf mcpServerType;
      default = { };
      description = "MCP servers contributed by agent integration modules.";
    };

    hooks = mkOption {
      type = types.attrsOf (types.attrsOf (types.listOf hookGroupType));
      default = { };
      description = "Hook groups contributed by integration modules, keyed by agent and event.";
    };
  };
}
