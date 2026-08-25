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

  pythonMcpStartup = {
    required = true;
    startup_timeout_sec = 60;
  };

  sharedMcpServers = mkMcpServers {
    inherit config;
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

  codexMcpConfigActivation = homeManagerLib.dag.entryAfter [ "writeBoundary" ] ''
    run ${codexMcpConfigUpdater}/bin/update-codex-mcp-config \
      ${escapeShellArg "${config.modules.agents.code.codex.configHome}/config.toml"}
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
