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
      default = if isDarwin then "${config.xdg.configHome}/codex" else "$XDG_CONFIG_HOME/codex";
      description = "Codex XDG configuration directory.";
    };
  };

  config = mkIf config.modules.agents.code.codex.enable (mkMerge [
    (mkIf config.modules.shell.zsh.enable {
      modules.shell.zsh.env = shellExports codexEnvVars;
    })

    (optionalAttrs (!isDarwin) {
      user.packages = codexPackages;
      env = codexEnvVars;
    })

    (optionalAttrs isDarwin {
      home.packages = codexPackages;
      home.sessionVariables = codexEnvVars;
    })
  ]);
}
