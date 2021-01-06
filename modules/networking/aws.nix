# modules/networking/aws.nix --- https://aws.amazon.com/
#
# Amazon Web Services, biggest Cloud player (ATM of this writing).
# Built on top of a prototype to manage VMs at Amazon.

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.networking.aws = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    iamAuthenticator.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.networking.aws.enable (mkMerge [
    {
      user.packages = with pkgs; [ awscli ];

      env.AWS_CONFIG_FILE = "$XDG_CONFIG_HOME/aws/config";
      env.AWS_SHARED_CREDENTIALS_FILE = "$XDG_CONFIG_HOME/aws/credentials";
      env.BOTO_CONFIG = "$XDG_CONFIG_HOME/boto/config";
    }

    (mkIf config.modules.networking.aws.iamAuthenticator.enable {
      user.packages = with pkgs; [ aws-iam-authenticator ];
    })
  ]);
}
