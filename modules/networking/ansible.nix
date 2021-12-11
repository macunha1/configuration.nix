# modules/networking/ansible.nix -- https://ansible.com/
#
# Before the invention of the hyper-hyped Kubernetes engine, our ancestors were
# driving systems moved by Ansible. Nowadays, you can still find some lost
# Ansible adoptors out there, you just need to look into a few caves.
#
# Jokes apart, this is the best option to keep fleets of VMs updated when
# HashiCorp Packer and Kubernetes aren't easy/feasible options.

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.networking.ansible = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.networking.ansible.enable {
    user.packages = with pkgs; [ ansible-lint my.molecule ansible ];

    env.ANSIBLE_ROLES_PATH = "$XDG_DATA_HOME/ansible/galaxy/roles";
    env.ANSIBLE_COLLECTIONS_PATH = "$XDG_DATA_HOME/ansible/galaxy/collections";

    env.ANSIBLE_GALAXY_CACHE_DIR = "$XDG_DATA_HOME/ansible/galaxy/cache";
    env.ANSIBLE_GALAXY_TOKEN_PATH = "$XDG_CONFIG_HOME/ansible/galaxy/token";
  };
}
