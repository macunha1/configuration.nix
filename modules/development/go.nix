# development/go.nix -- https://golang.org
#
# The de-facto cloud system's programming language.
#
# Linux: packages include libcap, a Linux-only dependency used by some Go tools.
# Darwin: libcap is a Linux kernel capability API and is not available on macOS.

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
  # Go environment — same values on both platforms.
  goEnvVars = {
    GOPATH = config.modules.development.go.path;
  };
in
{
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

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) (mkMerge [
      {
        user.packages = with pkgs; [
          libcap # Linux-only: POSIX capabilities (used by some Go tools)
          go
        ];
        env = goEnvVars;
      }

      (mkIf config.modules.development.go.languageServer.enable {
        user.packages = with pkgs; [ gopls ];
      })

      (mkIf config.modules.development.go.includeBinToPath {
        env.PATH = [ "$GOPATH/bin" ];
      })
    ]))

    # Darwin (MacOS)
    (optionalAttrs isDarwin (mkMerge [
      {
        home.packages = with pkgs; [ go ];
        home.sessionVariables = goEnvVars;
      }

      (mkIf config.modules.development.go.languageServer.enable {
        home.packages = with pkgs; [ gopls ];
      })

      (mkIf config.modules.development.go.includeBinToPath {
        home.sessionPath = [ "$GOPATH/bin" ];
      })
    ]))
  ]);
}
