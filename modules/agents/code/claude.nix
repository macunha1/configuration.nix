# agents/claude.nix -- https://github.com/anthropics/claude-code
#
# Anthropic Claude Code command-line coding agent.
#
{
  config,
  options,
  inputs,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:

with lib;

let
  inherit (lib.my or (import ../../../lib/generators.nix { inherit lib pkgs; }))
    shellExports
    ;

  inherit (lib.my or (import ../../../lib/modules/utils.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  inherit (lib.my or (import ../../../lib/modules/agents/mcp.nix { inherit lib; }))
    managedMcpServerNames
    mkMcpServers
    ;

  xdg = (lib.my or (import ../../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  homeManagerLib = inputs.home-manager.lib.hm;

  claudePackages = with pkgs; [
    claude-code
  ];

  claudeEnvVars = {
    CLAUDE_CONFIG_DIR = config.modules.agents.code.claude.configHome;
  };

  userProfileDirectory =
    if isDarwin then config.home.profileDirectory else "/etc/profiles/per-user/${config.user.name}";

  sharedMcpServers = mkMcpServers {
    inherit config;
    contextModePlatform = "claude-code";
    profileDirectory = userProfileDirectory;
  };

  claudeMcpServers = listToAttrs (
    map (
      server:
      nameValuePair server.name (
        {
          type = "stdio";
        }
        // removeAttrs server [ "name" ]
      )
    ) sharedMcpServers
  );

  claudeMcpServersJson = pkgs.writeText "claude-mcp-servers.json" (builtins.toJSON claudeMcpServers);
  managedMcpServerNamesJson = pkgs.writeText "claude-managed-mcp-server-names.json" (
    builtins.toJSON managedMcpServerNames
  );

  claudeMcpConfigUpdater = pkgs.writeShellApplication {
    name = "update-claude-mcp-config";
    runtimeInputs = [ pkgs.python3 ];

    text = ''
      python3 - "$1" "${claudeMcpServersJson}" "${managedMcpServerNamesJson}" <<'PY'
      import json
      import os
      import stat
      import sys
      from pathlib import Path

      def expand_xdg_paths(value):
          xdg_defaults = {
              "XDG_CACHE_HOME": Path.home() / ".cache",
              "XDG_CONFIG_HOME": Path.home() / ".config",
              "XDG_DATA_HOME": Path.home() / ".local/share",
              "XDG_STATE_HOME": Path.home() / ".local/state",
          }

          if isinstance(value, str):
              for variable, default in xdg_defaults.items():
                  value = value.replace(f"''${variable}", os.environ.get(variable, str(default)))
              return value
          if isinstance(value, list):
              return [expand_xdg_paths(item) for item in value]
          if isinstance(value, dict):
              return {key: expand_xdg_paths(item) for key, item in value.items()}
          return value

      config_path = Path(expand_xdg_paths(sys.argv[1]))
      desired_servers = expand_xdg_paths(json.loads(Path(sys.argv[2]).read_text()))
      managed_server_names = json.loads(Path(sys.argv[3]).read_text())

      config_data = {}
      if config_path.exists():
          config_data = json.loads(config_path.read_text())

      current_servers = config_data.get("mcpServers", {})
      for server_name in managed_server_names:
          current_servers.pop(server_name, None)
      current_servers.update(desired_servers)
      config_data["mcpServers"] = current_servers

      desired = json.dumps(config_data, indent=2) + "\n"
      current = config_path.read_text() if config_path.exists() else None
      if current != desired:
          config_path.parent.mkdir(parents=True, exist_ok=True)
          temporary_path = config_path.with_name(f".{config_path.name}.tmp")
          temporary_path.write_text(desired)
          if config_path.exists():
              temporary_path.chmod(stat.S_IMODE(config_path.stat().st_mode))
          temporary_path.replace(config_path)
      PY
    '';
  };

  claudeMcpConfigActivation = homeManagerLib.dag.entryAfter [ "writeBoundary" ] ''
    run ${claudeMcpConfigUpdater}/bin/update-claude-mcp-config \
      ${escapeShellArg "${config.modules.agents.code.claude.configHome}/.claude.json"}
  '';
in
{
  options.modules.agents.code.claude = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    configHome = mkOption {
      type = with types; either str path;
      default = xdg.concrete.config "claude";
      description = "Claude Code XDG configuration directory.";
    };
  };

  config = mkIf config.modules.agents.code.claude.enable (mkMerge [
    (platformPackages {
      inherit isDarwin;
      packages = claudePackages;
    })

    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = claudeEnvVars;
      target = "both";
    })

    (
      if isDarwin then
        { home.activation.updateClaudeMcpConfig = claudeMcpConfigActivation; }
      else
        {
          home-manager.users.${config.user.name}.home.activation.updateClaudeMcpConfig =
            claudeMcpConfigActivation;
        }
    )
  ]);
}
