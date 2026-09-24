# agents/mcp/codegraphcontext.nix -- https://github.com/macunha1/CodeGraphContext
#
# Code graph indexing CLI and MCP server.
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
  # Some standalone evaluations pass plain nixpkgs.lib, so lib.my may be absent.
  # Import the generator directly in that case.
  inherit (lib.my or (import ../../../lib/generators.nix { inherit lib pkgs; }))
    generatedFileWarning
    shellExports
    ;

  inherit (lib.my or (import ../../../lib/modules/utils.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  xdg = (lib.my or (import ../../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  codegraphcontextPython = pkgs.python314;

  codegraphcontextRuntimeInputs = [
    codegraphcontextPython
    pkgs.redis
    pkgs.uv
  ];

  codegraphcontextRuntimeEnv = optionalString (!isDarwin) ''
    export LD_LIBRARY_PATH="${
      makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]
    }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';

  # uv and Apple system executables strip DYLD_INSERT_LIBRARIES before starting
  # Python entry points. Set it in a Nix launcher after uv so FalkorDB Lite can
  # resolve its unlinked CoreFoundation symbols.
  darwinRuntimeLauncher = pkgs.writeShellScript "codegraphcontext-darwin-runtime" ''
    ${generatedFileWarning { file = ./codegraphcontext.nix; }}
    set -o errexit
    set -o nounset
    set -o pipefail

    toolName="$1"
    shift
    toolPath="$(command -v "$toolName")"

    export DYLD_INSERT_LIBRARIES="/System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation"
    exec "''${toolPath%/*}/python" "$toolPath" "$@"
  '';

  darwinRuntimePrefix = optionalString isDarwin "${darwinRuntimeLauncher}";

  codegraphcontextPackage = pkgs.writeShellApplication {
    name = "codegraphcontext";
    runtimeInputs = codegraphcontextRuntimeInputs;

    text = ''
      ${generatedFileWarning { file = ./codegraphcontext.nix; }}
      ${codegraphcontextRuntimeEnv}
      exec uv tool run --python "${getExe codegraphcontextPython}" \
        --from "${config.modules.agents.mcp.codegraphcontext.source}" \
        ${darwinRuntimePrefix} codegraphcontext "$@"
    '';
  };

  cgcPackage = pkgs.writeShellApplication {
    name = "cgc";
    runtimeInputs = codegraphcontextRuntimeInputs;

    text = ''
      ${generatedFileWarning { file = ./codegraphcontext.nix; }}
      ${codegraphcontextRuntimeEnv}
      exec uv tool run --python "${getExe codegraphcontextPython}" \
        --from "${config.modules.agents.mcp.codegraphcontext.source}" \
        ${darwinRuntimePrefix} cgc "$@"
    '';
  };

  codegraphcontextPackages = [
    codegraphcontextPackage
    cgcPackage
  ];

  codegraphcontextEnvVars = {
    DEFAULT_DATABASE = "falkordb";
    CGC_CONFIG_DIR = config.modules.agents.mcp.codegraphcontext.configHome;
    CGC_DATA_DIR = config.modules.agents.mcp.codegraphcontext.dataHome;
    CGC_CACHE_DIR = config.modules.agents.mcp.codegraphcontext.cacheHome;
    FALKORDB_PATH = "${config.modules.agents.mcp.codegraphcontext.dataHome}/global/db/falkordb";
    FALKORDB_SOCKET_PATH = "${config.modules.agents.mcp.codegraphcontext.dataHome}/global/db/falkordb.sock";
    LOG_FILE_PATH = "${config.modules.agents.mcp.codegraphcontext.cacheHome}/logs/cgc.log";
    DEBUG_LOG_PATH = "${config.modules.agents.mcp.codegraphcontext.cacheHome}/logs/debug.log";
  };
in
{
  options.modules.agents.mcp.codegraphcontext = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    source = mkOption {
      type = types.str;
      default = "git+https://github.com/macunha1/CodeGraphContext@306745228cf7a219b484c316d3bd06c9c2497e5a";
      description = "Pinned Python package source for the CodeGraphContext fork.";
    };

    configHome = mkOption {
      type = with types; either str path;
      default = xdg.concrete.config "codegraphcontext";
      description = "CodeGraphContext configuration directory.";
    };

    dataHome = mkOption {
      type = with types; either str path;
      default = xdg.concrete.data "codegraphcontext";
      description = "CodeGraphContext data directory.";
    };

    cacheHome = mkOption {
      type = with types; either str path;
      default = xdg.concrete.cache "codegraphcontext";
      description = "CodeGraphContext cache directory.";
    };
  };

  config = mkIf config.modules.agents.mcp.codegraphcontext.enable (mkMerge [
    # CodeGraphContext's redislite dependency starts a bundled generic Linux
    # redis-server binary instead of resolving redis-server from PATH. NixOS
    # needs nix-ld to execute that binary.
    (optionalAttrs (!isDarwin) {
      programs.nix-ld.enable = true;
    })

    (platformPackages {
      inherit isDarwin;
      packages = codegraphcontextPackages;
    })

    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = codegraphcontextEnvVars;
      target = "both";
    })
  ]);
}
