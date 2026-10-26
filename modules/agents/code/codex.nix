# agents/codex.nix -- https://github.com/openai/codex
#
# OpenAI Codex command-line coding agent.
#
{
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:

with lib;

let
  inherit (lib.my or (import ../../../lib/generators.nix { inherit lib pkgs; }))
    generatedFileWarning
    shellExports
    ;

  inherit (lib.my or (import ../../../lib/modules/utils.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  inherit (lib.my or (import ../../../lib/modules/agents/integrations.nix { inherit lib; }))
    renderAgentHooks
    renderMcpServers
    ;

  xdg = (lib.my or (import ../../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  homeManagerConfig = if isDarwin then config else config.home-manager.users.${config.user.name};

  codexConfigHome =
    replaceStrings
      [
        "$XDG_CACHE_HOME"
        "$XDG_CONFIG_HOME"
        "$XDG_DATA_HOME"
        "$XDG_STATE_HOME"
      ]
      [
        (toString homeManagerConfig.xdg.cacheHome)
        (toString homeManagerConfig.xdg.configHome)
        (toString homeManagerConfig.xdg.dataHome)
        (toString homeManagerConfig.xdg.stateHome)
      ]
      (toString config.modules.agents.code.codex.configHome);

  codexConfigHomeRelative = removePrefix "${toString homeManagerConfig.home.homeDirectory}/" codexConfigHome;

  codexManagedProfileName = "nix-managed";

  codexManagedProfilePath = "${codexConfigHome}/${codexManagedProfileName}.config.toml";

  codexProfileWrapper = pkgs.writeShellScript "codex-with-managed-profile" ''
    set -e

    codex_command=""
    debug_prompt_input=false

    for argument in "$@"; do
      case "$argument" in
        -p|--profile|--profile=*)
          exec ${pkgs.codex}/bin/codex "$@"
          ;;
        -h|--help|-V|--version)
          exec ${pkgs.codex}/bin/codex "$@"
          ;;
        prompt-input)
          debug_prompt_input=true
          ;;
        agents|exec|review|login|logout|mcp|plugin|app-server|remote-control|app|completion|update|doctor|debug|apply|resume|queue|archive|delete|unarchive|fork|cloud|exec-server|features|help|sandbox)
          if [[ -z "$codex_command" ]]; then
            codex_command="$argument"
          fi
          ;;
      esac
    done

    case "$codex_command" in
      login|logout|plugin|app-server|remote-control|app|completion|update|doctor|apply|cloud|exec-server|features|help|agents)
        exec ${pkgs.codex}/bin/codex "$@"
        ;;
      debug)
        if [[ "$debug_prompt_input" != true ]]; then
          exec ${pkgs.codex}/bin/codex "$@"
        fi
        ;;
    esac

    exec ${pkgs.codex}/bin/codex --profile ${escapeShellArg codexManagedProfileName} "$@"
  '';

  codexPackage = pkgs.symlinkJoin {
    name = "codex-${pkgs.codex.version}-nix-managed";
    paths = [ pkgs.codex ];
    postBuild = ''
      ln -sfn ${codexProfileWrapper} "$out/bin/codex"
    '';
  };

  codexPackages = [ (if isDarwin then codexPackage else pkgs.codex) ];

  codexEnvVars = {
    CODEX_HOME = config.modules.agents.code.codex.configHome;
  };

  codexHooks = renderAgentHooks {
    inherit config;
    agent = "codex";
  };

  codexMcpServers = renderMcpServers {
    inherit config;
    agent = "codex";
  };

  # Codex treats profile hooks as user hooks, so they require an exact trust
  # hash even though Nix owns the profile. Pre-trust only the generated hook
  # definitions; changing a command, matcher, timeout, or list position changes
  # the corresponding hash and makes Codex request review again.
  codexHookEventNames = {
    PreToolUse = "pre_tool_use";
    PermissionRequest = "permission_request";
    PostToolUse = "post_tool_use";
    PreCompact = "pre_compact";
    PostCompact = "post_compact";
    SessionStart = "session_start";
    SessionEnd = "session_end";
    UserPromptSubmit = "user_prompt_submit";
    SubagentStart = "subagent_start";
    SubagentStop = "subagent_stop";
    Stop = "stop";
    Interrupt = "interrupt";
  };

  codexMatcherEvents = [
    "PreToolUse"
    "PermissionRequest"
    "PostToolUse"
    "PreCompact"
    "PostCompact"
    "SessionStart"
    "SessionEnd"
    "SubagentStart"
    "SubagentStop"
  ];

  codexHookTrust = listToAttrs (
    flatten (
      mapAttrsToList (
        event: groups:
        flatten (
          imap0 (
            groupIndex: group:
            imap0 (
              handlerIndex: hook:
              let
                eventName = codexHookEventNames.${event};
                identity = {
                  event_name = eventName;
                  hooks = [
                    (hook // { async = false; })
                  ];
                }
                // optionalAttrs (elem event codexMatcherEvents && group ? matcher) {
                  inherit (group) matcher;
                };
              in
              nameValuePair
                "${codexManagedProfilePath}:${eventName}:${toString groupIndex}:${toString handlerIndex}"
                {
                  trusted_hash = "sha256:${builtins.hashString "sha256" (builtins.toJSON identity)}";
                }
            ) group.hooks
          ) groups
        )
      ) codexHooks
    )
  );

  codexManagedConfig = (pkgs.formats.toml { }).generate "${codexManagedProfileName}.config.toml" (
    {
      inherit (config.modules.agents.code.codex) model;
      model_reasoning_effort = config.modules.agents.code.codex.modelReasoningEffort;
      tui = {
        alternate_screen = "never";
        theme = config.modules.agents.code.codex.theme;
      };
    }
    // optionalAttrs (codexMcpServers != { }) {
      mcp_servers = codexMcpServers;
    }
    // optionalAttrs (codexHooks != { }) {
      features.hooks = true;
      hooks = codexHooks // optionalAttrs isDarwin { state = codexHookTrust; };
    }
  );

  codexRetrowaveTheme = pkgs.writeText "retrowave.tmTheme" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!--
    ${generatedFileWarning {
      file = ../../../config/codex/retrowave.tmTheme;
      comment = "";
    }}
    -->
    ${builtins.readFile ../../../config/codex/retrowave.tmTheme}
  '';

  codexManagedHomeFiles = {
    "${codexConfigHomeRelative}/themes/retrowave.tmTheme" = {
      force = true;
      source = codexRetrowaveTheme;
    };
  }
  // optionalAttrs isDarwin {
    "${codexConfigHomeRelative}/${codexManagedProfileName}.config.toml" = {
      force = true;
      source = codexManagedConfig;
    };
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

    model = mkOption {
      type = types.str;
      default = "gpt-6.1-sol";
      description = "Default Codex model.";
    };

    modelReasoningEffort = mkOption {
      type = types.enum [
        "minimal"
        "low"
        "medium"
        "high"
        "xhigh"
      ];
      default = "high";
      description = "Default Codex model reasoning effort.";
    };

    theme = mkOption {
      type = types.str;
      default = "retrowave";
      description = "Codex syntax-highlighting theme.";
    };

    remoteControl.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Start the Codex managed remote-control daemon at login.";
    };
  };

  config = mkIf config.modules.agents.code.codex.enable (mkMerge [
    {
      assertions = [
        {
          assertion = hasPrefix "${toString homeManagerConfig.home.homeDirectory}/" codexConfigHome;
          message = "modules.agents.code.codex.configHome must be inside the managed user's home directory.";
        }
      ];
    }

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

    (optionalAttrs (!isDarwin) {
      environment.etc."codex/config.toml".source = codexManagedConfig;

      home-manager.users.${config.user.name} = {
        home.file = codexManagedHomeFiles;

        systemd.user.services.codex-remote-control =
          mkIf config.modules.agents.code.codex.remoteControl.enable
            {
              Unit.Description = "Enable Codex remote control";

              Service = {
                Environment = [
                  "CODEX_HOME=${codexConfigHome}"
                ];
                ExecStart = "${pkgs.codex}/bin/codex remote-control start";
                RemainAfterExit = true;
                Type = "oneshot";
              };

              Install.WantedBy = [ "default.target" ];
            };
      };
    })

    (optionalAttrs isDarwin {
      home.file = codexManagedHomeFiles;
    })
  ]);
}
