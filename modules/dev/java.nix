# modules/dev/java.nix --- https://www.java.com/en/
#
# Java ooh Java, why you have to be so ugly and nice at the same time?
# You are the perfect mid-term between performance and productivity.
# I've tried to avoid you for many years, but I can't resist.

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.dev.java = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.dev.java.enable {
    my = {
      packages = with pkgs; [
        openjdk
      ];
    };

    programs.java.enable = true;
  };
}
