# development/java.nix -- https://www.java.com/en/
#
# Java ooh Java, why you have to be so ugly and nice at the same time?
# You are the perfect mid-term between performance and productivity.
# I've tried to avoid you for many years, but I can't resist.

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
  gradleEnvVars = {
    GRADLE_USER_HOME = config.modules.development.java.gradle.userHome;
  };
in
{
  options.modules.development.java = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    gradle = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      userHome = mkOption {
        type = types.str;
        default = "$XDG_CONFIG_HOME/gradle";
      };
    };
  };

  config = mkIf config.modules.development.java.enable (mkMerge [
    {
      programs.java = {
        enable = true;
        package = pkgs.openjdk21; # Java 21 LTS (supported until Sep 2031)
      };
    }

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) (
      mkIf config.modules.development.java.gradle.enable {
        user.packages = with pkgs; [ gradle ];
        env = gradleEnvVars;
      }
    ))

    # Darwin (MacOS)
    (optionalAttrs isDarwin (
      mkIf config.modules.development.java.gradle.enable {
        home.packages = with pkgs; [ gradle ];
        modules.shell.zsh.env = ''
          export GRADLE_USER_HOME="${config.modules.development.java.gradle.userHome}"
        '';
      }
    ))
  ]);
}
