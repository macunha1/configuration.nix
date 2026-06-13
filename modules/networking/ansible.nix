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

{ config, options, lib, pkgs, isDarwin ? pkgs.stdenv.isDarwin, ... }:

with lib;

let
  ## my.molecule is a custom overlay package; may require the overlay on Darwin.
  ansiblePackages = with pkgs; [
    ansible-lint # best-practice rule checker for playbooks
    my.molecule  # test framework for Ansible roles
    ansible      # the automation engine itself
  ];

  ## XDG-compliant Ansible paths — same values on both platforms.
  ansibleEnvVars = {
    ANSIBLE_ROLES_PATH       = "$XDG_DATA_HOME/ansible/galaxy/roles";
    ANSIBLE_COLLECTIONS_PATH = "$XDG_DATA_HOME/ansible/galaxy/collections";
    ANSIBLE_GALAXY_CACHE_DIR = "$XDG_DATA_HOME/ansible/galaxy/cache";
    ANSIBLE_GALAXY_TOKEN_PATH = "$XDG_CONFIG_HOME/ansible/galaxy/token";
  };
in
{
  options.modules.networking.ansible = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.networking.ansible.enable (mkMerge [

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = ansiblePackages;
      env = ansibleEnvVars;
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      home.packages = ansiblePackages;
      home.sessionVariables = ansibleEnvVars;
    })
  ]);
}
