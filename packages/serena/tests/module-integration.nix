# Evaluate with the flake passed explicitly so new worktree files are included.
{ flake }:
let
  lib = flake.inputs.nixpkgs.lib;
  home = flake.homeConfigurations.mcunha;
  linux = flake.nixosConfigurations.nixosmos;
  homeWith = settings: (home.extendModules { modules = [ settings ]; }).config;
  linuxWith = settings: (linux.extendModules { modules = [ settings ]; }).config;
  providerCases = [
    {
      key = "cpp_ccls";
      path = [
        "development"
        "cc"
      ];
    }
    {
      key = "lua";
      path = [
        "development"
        "lua"
      ];
    }
    {
      key = "typescript";
      path = [
        "development"
        "node"
      ];
    }
    {
      key = "python";
      path = [
        "development"
        "python"
      ];
    }
    {
      key = "go";
      path = [
        "development"
        "go"
      ];
    }
    {
      key = "rust";
      path = [
        "development"
        "rust"
      ];
    }
    {
      key = "elixir";
      path = [
        "development"
        "elixir"
      ];
    }
    {
      key = "bash";
      path = [
        "development"
        "bash"
      ];
    }
    {
      key = "nix";
      path = [
        "development"
        "nix"
      ];
    }
    {
      key = "terraform";
      path = [
        "networking"
        "terraform"
      ];
    }
    {
      key = "ansible";
      path = [
        "networking"
        "ansible"
      ];
    }
    {
      key = "yaml";
      path = [
        "networking"
        "kubernetes"
      ];
    }
    {
      key = "helm";
      path = [
        "networking"
        "kubernetes"
        "helm"
      ];
    }
  ];
  casesFor =
    evaluate:
    lib.concatMap (
      provider:
      map
        (gate: {
          name = "${provider.key}-${lib.concatStringsSep "-" gate}-disabled";
          value =
            !(builtins.hasAttr provider.key
              (evaluate (lib.setAttrByPath ([ "modules" ] ++ provider.path ++ gate) (lib.mkForce false)))
              .modules.agents.integrations.languageServers
            );
        })
        [
          [ "enable" ]
          [
            "languageServer"
            "enable"
          ]
        ]
    ) providerCases;
  checkGates = evaluate: builtins.listToAttrs (casesFor evaluate);
  withoutSerena = homeWith { modules.agents.mcp.serena.enable = lib.mkForce false; };
  renderer = import ../../../lib/modules/agents/integrations.nix { inherit lib; };
  rendered =
    agent:
    renderer.renderMcpServers {
      config = home.config;
      inherit agent;
    };
  collision = homeWith (
    lib.mkMerge [
      { modules.development.python.languageServer.command = [ "/first/server" ]; }
      { modules.development.python.languageServer.command = [ "/second/server" ]; }
    ]
  );
  overridden = homeWith {
    modules.development.python.languageServer.command = [
      "/selected/zuban"
      "server"
    ];
  };
  privateProvider = homeWith (
    { config, pkgs, ... }:
    let
      helpers = import ../../../lib/modules/development/language-servers.nix { inherit lib; };
      server = config.modules.development.example.languageServer;
    in
    {
      options.modules.development.example.languageServer = helpers.mkLanguageServerOptions {
        config = server;
        package = pkgs.hello;
        adapter = "generic";
        extensions = [ ".example" ];
      };
      config = lib.mkMerge [
        { modules.development.example.languageServer.enable = true; }
        (lib.mkIf server.enable (
          helpers.mkLanguageServerContribution {
            name = "private-example";
            inherit server;
            isDarwin = true;
          }
        ))
      ];
    }
  );
  withCcls = linuxWith { modules.development.cc.languageServer.enable = lib.mkForce true; };
  withoutGrep = homeWith { modules.shell.grep.enable = lib.mkForce false; };
  withoutLinuxGrep = linuxWith { modules.shell.grep.enable = lib.mkForce false; };
in
{
  darwin = checkGates homeWith;
  linux = checkGates linuxWith;
  consumerDisabled = !(withoutSerena.modules.agents.integrations.mcpServers ? serena);
  bothAgentsUseManagedServer =
    (rendered "codex").serena.command == (rendered "claude").serena.command;
  conflictingCommandRejected =
    !(builtins.tryEval (
      builtins.deepSeq collision.modules.agents.integrations.languageServers.python.command true
    )).success;
  privateProviderUsesPublicSchema =
    privateProvider.modules.agents.integrations.languageServers ? private-example;
  ownerCommandReachesConsumer =
    overridden.modules.agents.integrations.languageServers.python.command
    == overridden.modules.development.python.languageServer.command;
  providerInstallsWithoutConsumer = builtins.elem withoutSerena.modules.development.python.languageServer.package withoutSerena.home.packages;
  astGrepOwnedByShell =
    builtins.elem home.pkgs.ast-grep home.config.home.packages
    && !(builtins.elem home.pkgs.ast-grep withoutGrep.home.packages)
    && builtins.elem linux.pkgs.ast-grep linux.config.users.users.${linux.config.user.name}.packages
    && !(builtins.elem linux.pkgs.ast-grep
      withoutLinuxGrep.users.users.${withoutLinuxGrep.user.name}.packages
    );
  existingChoicesPreserved =
    home.config.modules.agents.integrations.languageServers.python.package.pname == "zuban"
    && withCcls.modules.agents.integrations.languageServers.cpp_ccls.package.pname == "ccls"
    &&
      linux.config.modules.agents.integrations.languageServers.typescript.package.pname
      == "javascript-typescript-langserver";
}
