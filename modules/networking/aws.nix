# modules/networking/aws.nix -- https://aws.amazon.com/
#
# Amazon Web Services, biggest Cloud player (ATM of this writing).
# Built on top of a prototype (EC2) developed to manage VMs at Amazon, AWS is
# the child of Amazon's fail-fast approach to business. Works great doesn't it?
#
# You can see the reflection of this fail-fast approach in the APIs. Consistency
# is unexistent.
#
# Linux: user.packages + env = awsEnvVars.
# Darwin: home.packages + modules.shell.zsh.env = awsEnvVars.

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
  awsPackages = with pkgs; [
    awscli # AWS CLI v1
  ];

  # XDG-compliant AWS credential paths - same values on both platforms.
  awsEnvVars = {
    AWS_CONFIG_FILE = "$XDG_CONFIG_HOME/aws/config";
    AWS_SHARED_CREDENTIALS_FILE = "$XDG_CONFIG_HOME/aws/credentials";
    BOTO_CONFIG = "$XDG_CONFIG_HOME/boto/config"; # Python boto2/boto3
  };
in
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

  config = mkIf config.modules.networking.aws.enable (mkMerge [

    # Both platforms: register aws_completer when zsh is enabled.
    (mkIf config.modules.shell.zsh.enable {
      modules.shell.zsh.init = ''
        complete -C aws_completer aws
      '';
    })

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) (mkMerge [
      {
        user.packages = awsPackages;
        env = awsEnvVars;
      }

      (mkIf config.modules.networking.aws.iamAuthenticator.enable {
        user.packages = with pkgs; [ aws-iam-authenticator ];
      })
    ]))

    # Darwin (MacOS)
    (optionalAttrs isDarwin (mkMerge [
      {
        home.packages = awsPackages;
        modules.shell.zsh.env = ''
          export AWS_CONFIG_FILE="${config.xdg.configHome}/aws/config"
          export AWS_SHARED_CREDENTIALS_FILE="${config.xdg.configHome}/aws/credentials"
          export BOTO_CONFIG="${config.xdg.configHome}/boto/config"
        '';
      }

      (mkIf config.modules.networking.aws.iamAuthenticator.enable {
        home.packages = with pkgs; [ aws-iam-authenticator ];
      })
    ]))
  ]);
}
