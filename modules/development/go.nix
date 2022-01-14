# development/go.nix -- https://golang.org
#
# The de-facto cloud system's programming language.

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.development.go = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    path = mkOption {
      type = with types; (either str path);
      default = "$XDG_DATA_HOME/go";
    };

    languageServer = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };

    includeBinToPath = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.go.enable (mkMerge [
    {
      user.packages = with pkgs.unstable; [ libcap go ];
      env.GOPATH = config.modules.development.go.path;
    }

    (mkIf config.modules.development.go.languageServer.enable {
      user.packages = with pkgs.unstable; [ gopls ];
    })

    (mkIf config.modules.development.go.includeBinToPath {
      env.PATH = [ "$GOPATH/bin" ];
    })
  ]);
}
