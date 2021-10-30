# networking/terraform.nix -- https://www.terraform.io/
#
# From the Chaos that is a Cloud Systems' Engineering life, Terraform is the
# only constant across configurations and providers.
#
# No matter if you're running a Data Lake, Serverless Web app or embedded
# system. On top of that at this point in time it doesn't even matter if you're
# using cloud, as you might as well order a Domino's pizza using Terraform.
# Ref: https://github.com/ndmckinley/terraform-provider-dominos

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.networking.terraform = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.networking.terraform.enable {

    # NOTE: This module won't install Terraform due to the highly inconsistent
    # amount of versions available (and in use) on the market. Instead, version
    # managers with support for Terraform are encouraged, either "tfenv" or
    # "asdf" with direnv integrated.
    #
    # ASDF module (modules/shell/asdf.nix) is enabled on nixosmos/modules.nix
    # that serves as an implementation example.

    home.configFile."terraform/rc.hcl".text = ''
      plugin_cache_dir = "$XDG_CACHE_HOME/terraform/plugins"

      disable_checkpoint           = true
      disable_checkpoint_signature = true
    '';

    env.TF_CLI_CONFIG_FILE = "$XDG_CONFIG_HOME/terraform/rc.hcl";
  };
}
