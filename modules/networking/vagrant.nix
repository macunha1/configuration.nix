# modules/networking/vagrant.nix --- https://www.vagrantup.com/
#
# Before Docker was a thing Vagrant was there creating ephemeral envs.
#
# Vagrant enables users to create and configure lightweight, reproducible, and
# portable development environments.

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.networking.vagrant = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    home = mkOption {
      type = with types; (either str path);
      default = "/opt/vagrant";
    };

    provider = mkOption {
      type = types.str;
      default = "virtualbox";
    };

    vCpus = mkOption {
      type = types.int;
      default = 2;
    };

    ramInGB = mkOption {
      type = types.int;
      default = 4;
    };
  };

  config = mkIf config.modules.networking.vagrant.enable {
    user.packages = with pkgs; [ vagrant ];

    # NOTE: Unofficial Vagrant variables from macunha1/Vagrantfiles
    # Ref: https://github.com/macunha1/Vagrantfiles
    env.VAGRANT_CPU_CORE = (toString config.modules.networking.vagrant.vCpus);
    env.VAGRANT_RAM_GB = (toString config.modules.networking.vagrant.ramInGB);
    env.VAGRANT_PROVIDER = config.modules.networking.vagrant.provider;

    env.VAGRANT_HOME = config.modules.networking.vagrant.home;

    home.dataFile."vagrant" = {
      source = pkgs.fetchFromGitHub {
        owner = "macunha1";
        repo = "Vagrantfiles";
        rev = "7e4c495536950281782f07b04e6e7dacd20134da";
        sha256 = "1rbp8cnpl8h6mrrgk5jd2q72rv57dszqn8vpc8mcfrrbw8ghxcbn";
      };

      recursive = true; # allows to have writable .vagrant dirs inside
    };
  };
}
