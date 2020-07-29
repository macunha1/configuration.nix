# modules/development/go.nix --- https://golang.org

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.development.go = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.go.enable {
    my = {
      packages = with pkgs; [
        libcap
        go
      ];

      # XDG variables aren't loading in time
      # env.GOPATH = "$XDG_DATA_HOME/go";
      # env.PATH = [ "$GOPATH/bin" ];
    };
  };
}
