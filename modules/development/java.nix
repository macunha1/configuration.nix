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
  inherit (lib.my or (import ../../lib/generators.nix { inherit lib pkgs; }))
    shellExports
    ;

  inherit (lib.my or (import ../../lib/modules.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

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
        default = xdg.concrete.config "gradle";
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

    (mkIf config.modules.development.java.gradle.enable (mkMerge [
      (platformPackages {
        inherit isDarwin;
        packages = with pkgs; [ gradle ];
      })

      (platformEnv {
        inherit config isDarwin;
        inherit shellExports;
        envVars = gradleEnvVars;
        darwinTarget = "zsh";
      })
    ]))
  ]);
}
