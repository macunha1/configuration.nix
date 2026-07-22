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
  options,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

with lib;

let
  inherit (lib.my or (import ../../lib/modules.nix { inherit lib; }))
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

  # XDG-compliant Ansible paths
  ansibleEnvVars = {
    ANSIBLE_ROLES_PATH = xdg.shell.data "ansible/galaxy/roles";
    ANSIBLE_COLLECTIONS_PATH = xdg.shell.data "ansible/galaxy/collections";
    ANSIBLE_GALAXY_CACHE_DIR = xdg.shell.data "ansible/galaxy/cache";
    ANSIBLE_GALAXY_TOKEN_PATH = xdg.shell.config "ansible/galaxy/token";
  };
in
{
  options.modules.networking.ansible = {
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
