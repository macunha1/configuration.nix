# modules/development/java.nix --- https://www.java.com/en/
#
# Java ooh Java, why you have to be so ugly and nice at the same time?
# You are the perfect mid-term between performance and productivity.
# I've tried to avoid you for many years, but I can't resist.

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.development.java = {
    enable = mkOption {
      type = types.bool;
      default = true;
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

  config = mkIf config.modules.development.java.enable {
    my = mkMerge [
      { packages = with pkgs; [ openjdk ]; }

      (mkIf config.modules.development.java.gradle.enable {
        packages = with pkgs; [ gradle ];

        env.GRADLE_USER_HOME = config.modules.development.java.gradle.userHome;
      })
    ];

    programs.java.enable = true;
  };
}
