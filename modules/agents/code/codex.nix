# agents/codex.nix -- https://github.com/openai/codex
#
# OpenAI Codex command-line coding agent.
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

  codexPackages = with pkgs; [
    codex
  ];

  codexEnvVars = {
    CODEX_HOME = config.modules.agents.code.codex.configHome;
  };

  userProfileDirectory =
    if isDarwin then config.home.profileDirectory else "/etc/profiles/per-user/${config.user.name}";

  contextModeCodexHookCommands = {
    PreToolUse = "context-mode hook codex pretooluse";
    PostToolUse = "context-mode hook codex posttooluse";
    SessionStart = "context-mode hook codex sessionstart";
    PreCompact = "context-mode hook codex precompact";
    UserPromptSubmit = "context-mode hook codex userpromptsubmit";
    Stop = "context-mode hook codex stop";
  };

  codexContextModeHooks = optionalAttrs config.modules.agents.plugins.context-mode.enable (
    mapAttrs (hookName: command: [
      {
        matcher =
          if hookName == "PreToolUse" then
            "local_shell|shell|shell_command|exec_command|Bash|Shell|apply_patch|Edit|Write|grep_files|ctx_execute|ctx_execute_file|ctx_batch_execute|ctx_fetch_and_index|ctx_search|ctx_index|mcp__"
          else
            "";
        hooks = [
          {
            type = "command";
            command = "${userProfileDirectory}/bin/${command}";
          }
        ];
      }
    ]) contextModeCodexHookCommands
  );

  pythonMcpStartup = {
    required = true;
    startup_timeout_sec = 60;
  };

  sharedMcpServers = mkMcpServers {
    inherit config;
    contextModePlatform = "codex";
    profileDirectory = userProfileDirectory;
  };

  codexMcpServers = map (
    server:
    if
      elem server.name [
        "mempalace"
        "CodeGraphContext"
      ]
    then
      pythonMcpStartup // server
    else
      server
  ) sharedMcpServers;

  codexMcpServersJson = pkgs.writeText "codex-mcp-servers.json" (builtins.toJSON codexMcpServers);
  managedMcpServerNamesJson = pkgs.writeText "codex-managed-mcp-server-names.json" (
    builtins.toJSON managedMcpServerNames
  );
  codexContextModeHooksJson = pkgs.writeText "codex-context-mode-hooks.json" (
    builtins.toJSON codexContextModeHooks
  );
  contextModeCodexHookCommandsJson = pkgs.writeText "context-mode-codex-hook-commands.json" (
    builtins.toJSON contextModeCodexHookCommands
  );

  codexMcpConfigUpdater = pkgs.writeShellApplication {
    name = "update-codex-mcp-config";
    runtimeInputs = [ pkgs.python3 ];

    text = ''
      python3 - "$1" "${codexMcpServersJson}" "${managedMcpServerNamesJson}" <<'PY'
      import json
      import os
      import sys
      from pathlib import Path

      def expand_xdg_path(value):
          xdg_defaults = {
              "XDG_CACHE_HOME": Path.home() / ".cache",
              "XDG_CONFIG_HOME": Path.home() / ".config",
              "XDG_DATA_HOME": Path.home() / ".local/share",
              "XDG_STATE_HOME": Path.home() / ".local/state",
          }

          for variable, default in xdg_defaults.items():
              value = value.replace(f"''${variable}", os.environ.get(variable, str(default)))

          return value

      config_path = Path(expand_xdg_path(sys.argv[1]))
      servers = json.loads(Path(sys.argv[2]).read_text())
      managed_server_names = set(json.loads(Path(sys.argv[3]).read_text()))

      def toml_value(value):
          if isinstance(value, bool):
              return "true" if value else "false"
          if isinstance(value, str):
              value = expand_xdg_path(value)
          return json.dumps(value)

      def section_name(line):
          stripped = line.strip()
          if stripped.startswith("[") and stripped.endswith("]"):
              return stripped.strip("[]")
          return None

      def managed_section(section):
          return any(
              section == f"mcp_servers.{name}" or section == f"mcp_servers.{name}.env"
              for name in managed_server_names
          )

      def ensure_boolean_setting(lines, target_section, setting_name, value):
          section_index = next(
              (index for index, line in enumerate(lines) if target_section == section_name(line)),
              None,
          )
          rendered = f"{setting_name} = {'true' if value else 'false'}"

          if section_index is None:
              if lines:
                  lines.append("")
              lines.extend([f"[{target_section}]", rendered])
              return

          section_end = next(
              (
                  index
                  for index in range(section_index + 1, len(lines))
                  if section_name(lines[index]) is not None
              ),
              len(lines),
          )
          setting_index = next(
              (
                  index
                  for index in range(section_index + 1, section_end)
                  if "=" in lines[index]
                  and lines[index].split("=", 1)[0].strip() == setting_name
              ),
              None,
          )

          if setting_index is None:
              lines.insert(section_index + 1, rendered)
          else:
              lines[setting_index] = rendered

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

      ensure_boolean_setting(lines, "features", "hooks", True)

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

  codexHooksConfigUpdater = pkgs.writeShellApplication {
    name = "update-codex-hooks-config";
    runtimeInputs = [ pkgs.python3 ];

    text = ''
      python3 - "$1" "${codexContextModeHooksJson}" "${contextModeCodexHookCommandsJson}" <<'PY'
      import json
      import os
      import stat
      import sys
      from pathlib import Path

      def expand_xdg_path(value):
          xdg_defaults = {
              "XDG_CACHE_HOME": Path.home() / ".cache",
              "XDG_CONFIG_HOME": Path.home() / ".config",
              "XDG_DATA_HOME": Path.home() / ".local/share",
              "XDG_STATE_HOME": Path.home() / ".local/state",
          }

          for variable, default in xdg_defaults.items():
              value = value.replace(f"''${variable}", os.environ.get(variable, str(default)))

          return value

      def entry_commands(entry):
          if not isinstance(entry, dict):
              return []
          hooks = entry.get("hooks", [])
          if not isinstance(hooks, list):
              return []
          return [
              hook.get("command", "")
              for hook in hooks
              if isinstance(hook, dict) and isinstance(hook.get("command"), str)
          ]

      config_path = Path(expand_xdg_path(sys.argv[1]))
      desired_hooks = json.loads(Path(sys.argv[2]).read_text())
      managed_commands = json.loads(Path(sys.argv[3]).read_text())

      config_data = {}
      if config_path.exists():
          config_data = json.loads(config_path.read_text())
          if not isinstance(config_data, dict):
              raise ValueError(f"{config_path} must contain a JSON object")

      hooks = config_data.get("hooks", {})
      if not isinstance(hooks, dict):
          raise ValueError(f"{config_path} hooks must be a JSON object")

      for hook_name, managed_command in managed_commands.items():
          current_entries = hooks.get(hook_name, [])
          if not isinstance(current_entries, list):
              raise ValueError(f"{config_path} hooks.{hook_name} must be a JSON array")

          entries = [
              entry
              for entry in current_entries
              if not any(managed_command in command for command in entry_commands(entry))
          ]
          entries.extend(desired_hooks.get(hook_name, []))

          if entries:
              hooks[hook_name] = entries
          else:
              hooks.pop(hook_name, None)

      if hooks:
          config_data["hooks"] = hooks
      else:
          config_data.pop("hooks", None)

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

  codexMcpConfigActivation = homeManagerLib.dag.entryAfter [ "writeBoundary" ] ''
    run ${codexMcpConfigUpdater}/bin/update-codex-mcp-config \
      ${escapeShellArg "${config.modules.agents.code.codex.configHome}/config.toml"}
    run ${codexHooksConfigUpdater}/bin/update-codex-hooks-config \
      ${escapeShellArg "${config.modules.agents.code.codex.configHome}/hooks.json"}
  '';
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

    (
      if isDarwin then
        { home.activation.updateCodexMcpConfig = codexMcpConfigActivation; }
      else
        {
          home-manager.users.${config.user.name}.home.activation.updateCodexMcpConfig =
            codexMcpConfigActivation;
        }
    )
  ]);
}
