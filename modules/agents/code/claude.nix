# agents/claude.nix -- https://github.com/anthropics/claude-code
#
# Anthropic Claude Code command-line coding agent.
#
{
  config,
  options,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

with lib;

let
  inherit (lib.my or (import ../../../lib/generators.nix { inherit lib pkgs; }))
    shellExports
    ;

  claudePackages = with pkgs; [
    claude-code
  ];

  claudeEnvVars = {
    CLAUDE_CONFIG_DIR = config.modules.agents.code.claude.configHome;
  };
in
{
  options.modules.agents.code.claude = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    configHome = mkOption {
      type = with types; either str path;
      default = if isDarwin then "${config.xdg.configHome}/claude" else "$XDG_CONFIG_HOME/claude";
      description = "Claude Code XDG configuration directory.";
    };
  };

  config = mkIf config.modules.agents.code.claude.enable (mkMerge [
    (mkIf config.modules.shell.zsh.enable {
      modules.shell.zsh.env = shellExports claudeEnvVars;
    })

    (optionalAttrs (!isDarwin) {
      user.packages = claudePackages;
      env = claudeEnvVars;
    })

    (optionalAttrs isDarwin {
      home.packages = claudePackages;
      home.sessionVariables = claudeEnvVars;
    })
  ]);
}
