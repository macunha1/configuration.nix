# agents/mcp/mempalace.nix -- https://github.com/MemPalace/mempalace
#
# Local-first AI memory exposed as an MCP server.

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
    ;

  xdg = (lib.my or (import ../../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  pythonRuntimeEnv = optionalString (!isDarwin) ''
    export LD_LIBRARY_PATH="${
      makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]
    }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';

  mempalacePackage = pkgs.writeShellApplication {
    name = "mempalace";

    text = ''
      ${pythonRuntimeEnv}
      exec ${config.modules.development.python.packageManagerRunCommand} \
        --from mempalace==3.7.0 mempalace "$@"
    '';
  };

  mempalaceMcpPackage = pkgs.writeShellApplication {
    name = "mempalace-mcp";

    text = ''
      ${pythonRuntimeEnv}
      exec ${config.modules.development.python.packageManagerRunCommand} \
        --from mempalace==3.7.0 mempalace-mcp "$@"
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
      default = xdg.concrete.data "mempalace/palace";
      description = "MemPalace data directory.";
    };
  };

  config = mkIf config.modules.agents.mcp.mempalace.enable (mkMerge [
    {
      modules.development.python.enable = true;
    }

    (platformPackages {
      inherit isDarwin;
      packages = mempalacePackages;
    })

    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = mempalaceEnvVars;
      target = "both";
    })
  ]);
}
