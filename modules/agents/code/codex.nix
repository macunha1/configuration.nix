# agents/codex.nix -- https://github.com/openai/codex
#
# OpenAI Codex command-line coding agent.
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

  codexPackages = with pkgs; [
    codex
  ];

  codexEnvVars = {
    CODEX_HOME = config.modules.agents.code.codex.configHome;
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
      darwinTarget = "both";
    })
  ]);
}
