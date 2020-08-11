# modules/networking/aws.nix --- https://aws.amazon.com/
#
# Amazon Web Services, biggest Cloud player (ATM of this writing).
# Built on top of a prototype to manage VMs at Amazon.

{ config, options, lib, pkgs, ... }:
with lib;
{
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

  config = mkMerge [
    (mkIf config.modules.networking.aws.enable {
      my.packages = with pkgs; [ awscli ];
    })  

    (mkIf config.modules.networking.aws.iamAuthenticator.enable {
      my.packages = with pkgs; [ aws-iam-authenticator ];
    })
  ];
}
