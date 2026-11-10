# modules/networking/ansible.nix -- https://ansible.com/
#
# Before the invention of the hyper-hyped Kubernetes engine, our ancestors were
# driving systems moved by Ansible. Nowadays, you can still find some lost
# Ansible adoptors out there, you just need to look into a few caves.
#
# Jokes apart, this is the best option to keep fleets of VMs updated when
# HashiCorp Packer and Kubernetes aren't easy/feasible options.
#
# Linux: user.packages + env = ansibleEnvVars.
# Darwin: home.packages + home.sessionVariables = ansibleEnvVars.

{
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:

with lib;

let
  inherit (lib.my or (import ../../lib/modules/development/language-servers.nix { inherit lib; }))
    mkLanguageServerOptions
    mkLanguageServerContribution
    ;
  inherit (lib.my or (import ../../lib/modules/utils.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  ansiblePackages =
    with pkgs;
    [
      ansible-lint # best-practice rule checker for playbooks
      ansible # the automation engine itself
    ]
    ++ optionals config.modules.networking.ansible.molecule.enable [
      pkgs.molecule # test framework for Ansible roles
    ];

  # Home Manager needs concrete Darwin paths; Linux keeps the XDG shell paths.
  ansibleEnvVars = {
    ANSIBLE_ROLES_PATH = xdg.concrete.data "ansible/galaxy/roles";
    ANSIBLE_COLLECTIONS_PATH = xdg.concrete.data "ansible/galaxy/collections";
    ANSIBLE_GALAXY_CACHE_DIR = xdg.concrete.data "ansible/galaxy/cache";
    ANSIBLE_GALAXY_TOKEN_PATH = xdg.concrete.config "ansible/galaxy/token";
  };
in
{
  options.modules.networking.ansible = {
    languageServer = mkLanguageServerOptions {
      config = config.modules.networking.ansible.languageServer;
      package = pkgs.ansible-language-server;
      environment = ansibleEnvVars;
      arguments = [ "--stdio" ];
      runtimePackages = [
        pkgs.ansible
        pkgs.ansible-lint
      ];
      languageId = "ansible";
    };
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    molecule = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf config.modules.networking.ansible.enable (mkMerge [
    (mkIf config.modules.networking.ansible.languageServer.enable (mkLanguageServerContribution {
      inherit isDarwin;
      name = "ansible";
      server = config.modules.networking.ansible.languageServer;
    }))
    (platformPackages {
      inherit isDarwin;
      packages = ansiblePackages;
    })

    (platformEnv {
      inherit config isDarwin;
      envVars = ansibleEnvVars;
    })
  ]);
}
