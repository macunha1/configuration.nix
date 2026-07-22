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

  inherit (lib.my or (import ../../../lib/modules.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  xdg = (lib.my or (import ../../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

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
      darwinTarget = "both";
    })
  ]);
}
