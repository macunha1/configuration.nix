{ lib }:
let
  inherit (import ../utils.nix { inherit lib; }) platformPackages;

  serverOptions = config: {
    package = lib.mkOption {
      type = lib.types.package;
      description = "The owning module's selected language-server package.";
    };
    arguments = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Arguments appended to the selected package executable by the default command.";
    };
    command = lib.mkOption {
      type = lib.types.uniq (lib.types.listOf lib.types.str);
      default = [ (lib.getExe config.package) ] ++ config.arguments;
      description = "Exact executable and arguments used by language-server consumers.";
    };
    runtimePackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Runtime tools required outside an interactive shell.";
    };
    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "The owning module's runtime environment.";
    };
    adapter = lib.mkOption {
      type = lib.types.enum [
        "builtin"
        "generic"
      ];
      default = "builtin";
      description = "Serena adapter implementation for the selected server.";
    };
    languageId = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "LSP document language identifier.";
    };
    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "File suffixes recognized by a generic adapter.";
    };
    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Selected adapter settings, including initialization options.";
    };
    filenamePattern = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional path expression restricting a generic adapter.";
    };
    priority = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Optional auto-detection priority; built-in adapters retain their upstream priority.";
    };
  };
in
{
  languageServerType = lib.types.submodule (
    { config, ... }: {
      options = serverOptions config;
    }
  );

  # Each caller declares these options under its own languageServer attribute.
  mkLanguageServerOptions =
    { config, ... }@defaults:
    lib.mapAttrs (
      name: option:
      option // lib.optionalAttrs (builtins.hasAttr name defaults) { default = defaults.${name}; }
    ) (serverOptions config // { enable = lib.mkEnableOption "the selected language server"; });

  # The provider's gate owns package installation and its derived contribution.
  mkLanguageServerContribution =
    {
      name,
      server,
      isDarwin,
    }:
    lib.mkMerge [
      (platformPackages {
        inherit isDarwin;
        packages = [ server.package ];
      })
      {
        modules.agents.integrations.languageServers.${name} =
          lib.getAttrs (builtins.attrNames (serverOptions server)) server;
      }
    ];
}
