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

  # FalkorDB Lite supplies its own Redis server and matching graph module.
  codegraphcontextRuntimeInputs = [
    codegraphcontextPython
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
      ${shellExports config.modules.agents.mcp.codegraphcontext.environment}
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
      ${shellExports config.modules.agents.mcp.codegraphcontext.environment}
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
in
{
  options.modules.agents.mcp.codegraphcontext = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    source = mkOption {
      type = types.str;
      default = "git+https://github.com/macunha1/CodeGraphContext@591d13e57dff8918f8886aeb826f8d07ba661394";
      description = "Pinned Python package source for the CodeGraphContext fork.";
    };

    enabledTools = mkOption {
      type = types.listOf types.str;
      default = [
        "get_graph_guide"
        "find_code"
        "analyze_code_relationships"
        "execute_cypher_query"
        "list_indexed_repositories"
        "get_repository_stats"
        "add_code_to_graph"
        "watch_directory"
        "list_watched_paths"
        "check_job_status"
        "list_jobs"
        "discover_codegraph_contexts"
        "switch_context"
      ];
      description = "Server-side tool allow list shared by every agent. An empty list exposes the full catalog.";
    };

    maxToolResponseTokens = mkOption {
      type = types.ints.unsigned;
      default = 4096;
      description = "CGC response budget using its approximate character conversion; zero disables the limit.";
    };

    scip = {
      enable = mkEnableOption "optional compiler-aware SCIP indexing";
      languages = mkOption {
        type = types.listOf (
          types.enum [
            "python"
            "go"
            "rust"
          ]
        );
        default = [
          "python"
          "go"
          "rust"
        ];
        description = "Languages selected for a SCIP trial; indexer executables and project environments must be available.";
      };
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

    environment = mkOption {
      type = types.attrsOf types.str;
      default = {
        DEFAULT_DATABASE = "falkordb";
        CGC_ENABLED_TOOLS = concatStringsSep "," config.modules.agents.mcp.codegraphcontext.enabledTools;
        MAX_TOOL_RESPONSE_TOKENS = toString config.modules.agents.mcp.codegraphcontext.maxToolResponseTokens;
        SCIP_INDEXER = if config.modules.agents.mcp.codegraphcontext.scip.enable then "true" else "false";
        SCIP_LANGUAGES = concatStringsSep "," config.modules.agents.mcp.codegraphcontext.scip.languages;
        CGC_CONFIG_DIR = config.modules.agents.mcp.codegraphcontext.configHome;
        CGC_DATA_DIR = config.modules.agents.mcp.codegraphcontext.dataHome;
        CGC_CACHE_DIR = config.modules.agents.mcp.codegraphcontext.cacheHome;
        FALKORDB_PATH = "${config.modules.agents.mcp.codegraphcontext.dataHome}/global/db/falkordb";
        FALKORDB_SOCKET_PATH = "${config.modules.agents.mcp.codegraphcontext.dataHome}/global/db/falkordb.sock";
        LOG_FILE_PATH = "${config.modules.agents.mcp.codegraphcontext.cacheHome}/logs/cgc.log";
        DEBUG_LOG_PATH = "${config.modules.agents.mcp.codegraphcontext.cacheHome}/logs/debug.log";
      };
      readOnly = true;
      internal = true;
      description = "Environment shared by CodeGraphContext launch surfaces.";
    };
  };

  config = mkIf config.modules.agents.mcp.codegraphcontext.enable (mkMerge [
    {
      modules.agents.integrations.mcpServers.CodeGraphContext = {
        command = "${codegraphcontextPackage}/bin/codegraphcontext";
        args = [
          "mcp"
          "start"
        ];
        env = config.modules.agents.mcp.codegraphcontext.environment;
        agents.codex.settings = {
          required = false;
          startup_timeout_sec = 60;
        };
      };
    }

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
      envVars = config.modules.agents.mcp.codegraphcontext.environment;
      target = "both";
    })
  ]);
}
