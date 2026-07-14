# agents/mcp/mempalace.nix -- https://github.com/MemPalace/mempalace
#
# Local-first AI memory exposed as an MCP server.

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

  mempalacePackage = pkgs.writeShellApplication {
    name = "mempalace";

    text = ''
      exec ${config.modules.development.python.packageManagerCommand} tool \
        run --from mempalace mempalace "$@"
    '';
  };

  mempalaceMcpPackage = pkgs.writeShellApplication {
    name = "mempalace-mcp";

    text = ''
      exec ${config.modules.development.python.packageManagerCommand} tool \
        run --from mempalace mempalace-mcp "$@"
    '';
  };

  mempalacePackages = [
    mempalacePackage
    mempalaceMcpPackage
  ];

  mempalaceEnvVars = {
    MEMPALACE_PALACE_PATH = config.modules.agents.mcp.mempalace.palacePath;
  };
in
{
  options.modules.agents.mcp.mempalace = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    palacePath = mkOption {
      type = with types; either str path;
      default =
        if isDarwin then "${config.xdg.dataHome}/mempalace/palace" else "$XDG_DATA_HOME/mempalace/palace";
      description = "MemPalace data directory.";
    };
  };

  config = mkIf config.modules.agents.mcp.mempalace.enable (mkMerge [
    {
      modules.development.python.enable = true;
    }

    (mkIf config.modules.shell.zsh.enable {
      modules.shell.zsh.env = shellExports mempalaceEnvVars;
    })

    (optionalAttrs (!isDarwin) {
      user.packages = mempalacePackages;
      env = mempalaceEnvVars;
    })

    (optionalAttrs isDarwin {
      home.packages = mempalacePackages;
      home.sessionVariables = mempalaceEnvVars;
    })
  ]);
}
