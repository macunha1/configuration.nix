{
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:
let
  inherit (lib.my or (import ../../../lib/generators.nix { inherit lib pkgs; })) shellExports;
  inherit (lib.my or (import ../../../lib/modules/utils.nix { inherit lib; })) platformPackages;
  xdg = (lib.my or (import ../../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  managedServers = config.modules.agents.integrations.languageServers;
  managedEnvironment = lib.zipAttrsWith (
    name: values:
    if builtins.length (lib.unique values) == 1 then
      builtins.head values
    else
      throw "Language server contributions disagree on environment variable ${name}"
  ) (map (server: server.environment) (lib.attrValues managedServers));

  managedAdapters = (pkgs.formats.json { }).generate "serena-language-servers.json" (
    lib.mapAttrs (_: server: {
      inherit (server)
        command
        adapter
        languageId
        extensions
        filenamePattern
        priority
        ;
    }) managedServers
  );

  managedConfiguration = (pkgs.formats.yaml { }).generate "serena-config.yml" (
    {
      projects = [ ];
      agent_interface = "REPL";
      included_apis = [ "lsp" ];
      excluded_apis = [
        "mem"
        "shell"
        "fs"
      ];
      web_dashboard = false;
      web_dashboard_open_on_launch = false;
      gui_log_window = false;
      default_max_tool_answer_chars = 16000;
    }
    // config.modules.agents.mcp.serena.settings
    // {
      ls_specific_settings = lib.mapAttrs (_: server: server.settings) managedServers;
    }
  );

  context = (pkgs.formats.yaml { }).generate "managed-agent.context.yml" {
    description = "Code intelligence alongside native agent tools, CGC, MemPalace, and context-mode";
    prompt = ''
      Use language-server operations for symbols, definitions, references, and supported refactorings.
      Fetch selected symbol bodies after locating them. Use CGC for repository graph traversal,
      exact search for literal strings, and native tools for file operations and validation.
      Keep persistent decisions in MemPalace. Filter intermediate results before returning them.
      A missing reference is not proof of absence; report server limitations and unresolved cases.
    '';
    excluded_tools = [
      "execute_shell_command"
      "read_file"
      "create_text_file"
    ];
    tool_description_overrides = { };
  };

  serenaPackage = pkgs.writeShellApplication {
    name = "serena";
    runtimeInputs = lib.concatMap (server: [ server.package ] ++ server.runtimePackages) (
      lib.attrValues managedServers
    );
    text = ''
      ${shellExports (
        managedEnvironment
        // {
          SERENA_HOME = toString config.modules.agents.mcp.serena.storageHome;
          SERENA_CONFIG_FILE = toString managedConfiguration;
          SERENA_LANGUAGE_SERVERS = toString managedAdapters;
        }
      )}
      exec ${lib.getExe config.modules.agents.mcp.serena.package} \
        start-mcp-server --project-from-cwd --context ${context} "$@"
    '';
  };
in
{
  options.modules.agents.mcp.serena = {
    enable = lib.mkEnableOption "Serena with module-owned language servers";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.my.serena.override { serenaSource = config.modules.agents.mcp.serena.source; };
      description = "Serena runtime package, including managed configuration and language-server registration support.";
    };

    source = lib.mkOption {
      type =
        with lib.types;
        oneOf [
          str
          path
          package
        ];
      default = pkgs.my.serena.src;
      description = "Source override for the default Serena package; must include its matching uv.lock.";
    };

    storageHome = lib.mkOption {
      type = with lib.types; either str path;
      default = xdg.concrete.data "serena";
      description = "Writable Serena runtime data and logs.";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Declarative Serena session settings; language server selection belongs to language modules.";
    };
  };
  config = lib.mkIf config.modules.agents.mcp.serena.enable (
    lib.mkMerge [
      (platformPackages {
        inherit isDarwin;
        packages = [ serenaPackage ];
      })

      {
        assertions = lib.mapAttrsToList (name: server: {
          assertion = server.command != [ ] && (server.adapter != "generic" || server.extensions != [ ]);
          message = "Language server ${name} requires a command and generic adapters require extensions.";
        }) managedServers;
        modules.agents.integrations.mcpServers.serena = {
          command = "${serenaPackage}/bin/serena";
          agents.codex.settings.startup_timeout_sec = 120;
        };
      }
    ]
  );
}
