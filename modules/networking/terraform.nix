# modules/networking/terraform.nix --- https://www.terraform.io/
#
# From the Chaos that is a Systems Engineer life, Terraform is the only constant.
# No matter if you're running a Data Lake, Serverless Web app or embedded system,

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.networking.terraform = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.networking.terraform.enable {
    # Use tfenv to manage multiple versions of TF
    # TODO: Create a writable tfenv/versions dir
    my.home.xdg.dataFile."tfenv" = {
      source = pkgs.fetchFromGitHub {
        owner = "tfutils";
        repo = "tfenv";
        rev = "v2.0.0";
        sha256 = "0ljx567ykbbdd7974953b9vbyjcf214m189bh2yn1sypaqyynvv6";
      };

      recursive = true;
    };

    my.env.PATH = [ "$XDG_DATA_HOME/tfenv/bin" ];
  };
}
