# agents/claude.nix -- https://github.com/anthropics/claude-code
#
# Anthropic Claude Code command-line coding agent.
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
    shellExports
    ;

  inherit (lib.my or (import ../../../lib/modules/utils.nix { inherit lib; }))
    platformEnv
    platformPackages
    platformPath
    ;

  inherit (lib.my or (import ../../../lib/modules/agents/integrations.nix { inherit lib; }))
    renderAgentHooks
    renderMcpServers
    ;

  xdg = (lib.my or (import ../../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  claudeEnvVars = {
    ANTHROPIC_MODEL = config.modules.agents.code.claude.model;
    CLAUDE_CODE_CERT_STORE = "bundled,system";
    CLAUDE_CODE_EFFORT_LEVEL = config.modules.agents.code.claude.effortLevel;
    CLAUDE_CODE_MCP_TOOL_IDLE_TIMEOUT = "120000";
    CLAUDE_CONFIG_DIR = config.modules.agents.code.claude.configHome;
    MCP_TOOL_TIMEOUT = "300000";
  };

  claudeHooks = renderAgentHooks {
    inherit config;
    agent = "claude";
  };

  claudeMcpServers = renderMcpServers {
    inherit config;
    agent = "claude";
    defaultSettings.type = "stdio";
  };

  claudeMcpConfigJson = pkgs.writeText "claude-mcp.json" (
    builtins.toJSON { mcpServers = claudeMcpServers; }
  );
  claudeSettingsJson = pkgs.writeText "claude-settings.json" (
    builtins.toJSON (
      {
        attribution = {
          commit = "";
          pr = "";
        };
        inherit (config.modules.agents.code.claude) effortLevel model;
        enabledPlugins = {
          "frontend-design@claude-plugins-official" = true;
        }
        //
          optionalAttrs
            (config.modules.development.go.enable && config.modules.development.go.languageServer.enable)
            {
              "gopls-lsp@claude-plugins-official" = true;
            }
        //
          optionalAttrs
            (config.modules.development.rust.enable && config.modules.development.rust.languageServer.enable)
            {
              "rust-analyzer-lsp@claude-plugins-official" = true;
            };
        skipAutoPermissionPrompt = true;
        tui = "default";
      }
      // optionalAttrs (claudeHooks != { }) {
        hooks = claudeHooks;
      }
      // optionalAttrs config.modules.shell.gnupg.enable {
        sandbox = {
          filesystem.allowWrite = [ (xdg.concrete.config "gpg") ];
          network.allowUnixSockets = map (socket: "${xdg.concrete.config "gpg"}/${socket}") [
            "S.gpg-agent"
            "S.gpg-agent.extra"
            "S.gpg-agent.browser"
            "S.gpg-agent.ssh"
            "S.scdaemon"
          ];
        };
      }
    )
  );

  # Apply Nix defaults to fresh sessions. Resumed sessions restore their saved
  # model unless the caller explicitly supplies --model. ANTHROPIC_MODEL also
  # prevents restoration, including when inherited from the managed shell.
  claudeLauncher = pkgs.writeShellScriptBin "claude" ''
    export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
    ${shellExports claudeEnvVars}
    model_args=(--model ${escapeShellArg config.modules.agents.code.claude.model})
    for argument in "$@"; do
      case "$argument" in
        --) break ;;
        --resume|--resume=*|-r|-r?*|--continue|-c)
          model_args=()
          unset ANTHROPIC_MODEL
          break
          ;;
      esac
    done
    exec ${pkgs.claude-code}/bin/claude \
      --settings ${claudeSettingsJson} \
      --mcp-config ${claudeMcpConfigJson} \
      "''${model_args[@]}" \
      "$@"
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

    model = mkOption {
      type = types.str;
      default = "claude-sonnet-5-5";
      description = "Claude Code model for fresh sessions; resumed sessions keep their saved model and --model can override either.";
    };

    effortLevel = mkOption {
      type = types.enum [
        "low"
        "medium"
        "high"
        "xhigh"
      ];
      default = "high";
      description = "Claude Code reasoning effort applied at every managed launch.";
    };

  };

  config = mkIf config.modules.agents.code.claude.enable (mkMerge [
    (platformPackages {
      inherit isDarwin;
      packages = [ claudeLauncher ];
    })

    (platformPath {
      inherit config isDarwin;
      paths = [ "${claudeLauncher}/bin" ];
      target = "both";
    })

    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = claudeEnvVars;
      target = "both";
    })

    (
      if isDarwin then
        {
          xdg.configFile."claude/settings.json" = {
            force = true;
            source = claudeSettingsJson;
          };
        }
      else
        {
          home.configFile."claude/settings.json" = {
            force = true;
            source = claudeSettingsJson;
          };
        }
    )
  ]);
}
