# agents/codex.nix -- https://github.com/openai/codex
#
# OpenAI Codex command-line coding agent.
#
{
  config,
  options,
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

  inherit (lib.my or (import ../../../lib/modules.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  xdg = (lib.my or (import ../../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  codexPackages = with pkgs; [
    codex
  ];

  codexEnvVars = {
    CODEX_HOME = config.modules.agents.code.codex.configHome;
  };

  codexMcpServers =
    optionals config.modules.agents.mcp.mempalace.enable [
      {
        name = "mempalace";
        command = "${config.home.profileDirectory}/bin/mempalace-mcp";
        env = {
          MEMPALACE_PALACE_PATH = config.modules.agents.mcp.mempalace.palacePath;
        };
      }
    ]
    ++ optionals config.modules.agents.plugins.context-mode.enable [
      {
        name = "context-mode";
        command = "${config.home.profileDirectory}/bin/context-mode";
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
        command = "${config.home.profileDirectory}/bin/codegraphcontext";
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

  codexMcpServersJson = pkgs.writeText "codex-mcp-servers.json" (builtins.toJSON codexMcpServers);

  codexMcpConfigUpdater = pkgs.writeShellApplication {
    name = "update-codex-mcp-config";
    runtimeInputs = [ pkgs.python3 ];

    text = ''
      python3 - "$1" "${codexMcpServersJson}" <<'PY'
      import json
      import sys
      from pathlib import Path

      config_path = Path(sys.argv[1])
      servers = json.loads(Path(sys.argv[2]).read_text())
      server_names = {server["name"] for server in servers}

      def toml_value(value):
          if isinstance(value, bool):
              return "true" if value else "false"
          return json.dumps(value)

      def section_name(line):
          stripped = line.strip()
          if stripped.startswith("[") and stripped.endswith("]"):
              return stripped.strip("[]")
          return None

      def managed_section(section):
          return any(
              section == f"mcp_servers.{name}" or section == f"mcp_servers.{name}.env"
              for name in server_names
          )

      lines = []
      if config_path.exists():
          current_section = None
          skipping = False

          for line in config_path.read_text().splitlines():
              section = section_name(line)
              if section is not None:
                  current_section = section
                  skipping = managed_section(current_section)

              if not skipping:
                  lines.append(line)

          while lines and lines[-1] == "":
              lines.pop()

      for server in servers:
          if lines:
              lines.append("")

          name = server["name"]
          lines.append(f"[mcp_servers.{name}]")
          lines.append(f"command = {toml_value(server['command'])}")

          if server.get("args"):
              lines.append(f"args = {toml_value(server['args'])}")

          for key, value in server.items():
              if key in {"name", "command", "args", "env"}:
                  continue
              lines.append(f"{key} = {toml_value(value)}")

          env = server.get("env", {})
          if env:
              lines.append("")
              lines.append(f"[mcp_servers.{name}.env]")
              for key in sorted(env):
                  lines.append(f"{key} = {toml_value(env[key])}")

      config_path.parent.mkdir(parents=True, exist_ok=True)
      desired = "\n".join(lines) + "\n"
      current = config_path.read_text() if config_path.exists() else None

      if current != desired:
          config_path.write_text(desired)
      PY
    '';
  };
in
{
  options.modules.agents.code.codex = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    configHome = mkOption {
      type = with types; either str path;
      default = xdg.concrete.config "codex";
      description = "Codex XDG configuration directory.";
    };
  };

  config = mkIf config.modules.agents.code.codex.enable (mkMerge [
    (platformPackages {
      inherit isDarwin;
      packages = codexPackages;
    })

    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = codexEnvVars;
      target = "both";
    })

    (optionalAttrs isDarwin (
      mkIf
        (
          config.modules.agents.mcp.mempalace.enable
          || config.modules.agents.plugins.context-mode.enable
          || config.modules.agents.mcp.codegraphcontext.enable
        )
        {
          home.activation.updateCodexMcpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run ${codexMcpConfigUpdater}/bin/update-codex-mcp-config \
              ${escapeShellArg "${config.modules.agents.code.codex.configHome}/config.toml"}
          '';
        }
    ))
  ]);
}
