# modules/development/go.nix --- https://golang.org

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.development.go = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    path = mkOption {
      type = types.path;
      default = "$XDG_DATA_HOME/go";
    };

    includeBinToPath = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.go.enable (mkMerge [
    {
      user.packages = with pkgs; [ libcap go ];
      env.GOPATH = config.modules.development.go.path;
    }

    (mkIf config.modules.development.go.includeBinToPath {
      env.PATH = [ "$GOPATH/bin" ];
    })
  ]);
}
