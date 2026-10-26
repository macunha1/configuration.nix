{ lib, ... }:

let
  inherit (lib)
    filterAttrs
    mapAttrs
    mapAttrs'
    nameValuePair
    optionalAttrs
    ;
in
{
  mkCommandHook = command: timeout: {
    inherit command timeout;
    type = "command";
  };

  renderAgentHooks =
    { config, agent }:
    mapAttrs (
      _event: groups:
      map (
        group:
        optionalAttrs (group.matcher != null) { inherit (group) matcher; } // { inherit (group) hooks; }
      ) groups
    ) (config.modules.agents.integrations.hooks.${agent} or { });

  renderMcpServers =
    {
      config,
      agent,
      defaultSettings ? { },
    }:
    mapAttrs'
      (
        serverName: server:
        let
          agentConfig = server.agents.${agent} or { };
          agentEnvironment = server.env // (agentConfig.env or { });
          agentServerName = agentConfig.name or null;
        in
        nameValuePair (if agentServerName == null then serverName else agentServerName) (
          defaultSettings
          // {
            inherit (server) command;
          }
          // optionalAttrs (server.args != [ ]) { inherit (server) args; }
          // optionalAttrs (agentEnvironment != { }) { env = agentEnvironment; }
          // (agentConfig.settings or { })
        )
      )
      (
        filterAttrs (
          _serverName: server:
          let
            agentConfig = server.agents.${agent} or { };
          in
          agentConfig.enable or true
        ) config.modules.agents.integrations.mcpServers
      );
}
