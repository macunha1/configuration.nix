# modules/networking/terraform.nix --- https://www.terraform.io/
#
# From the Chaos that is a Systems Engineer life, Terraform is the only constant.
# No matter if you're running a Data Lake, Serverless Web app or embedded system,

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.networking.terraform = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.networking.terraform.enable {
    # Use tfenv to manage multiple versions of TF
    my.home.xdg.dataHome."tfenv" = {
      source = builtins.fetchGit {
        url = "https://github.com/tfutils/tfenv";
      };
    };

    # TODO: Manage symlinks to ${HOME}/.local/bin
  };
}
