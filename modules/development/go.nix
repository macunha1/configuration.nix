# development/go.nix -- https://golang.org
#
# The de-facto cloud system's programming language.
#
# Linux: packages include libcap, a Linux-only dependency used by some Go tools.
# Darwin: libcap is a Linux kernel capability API and is not available on macOS.
# ZSH: exports XDG-backed Go paths and creates them for interactive shells.

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

  goBinPath = "${config.modules.development.go.path}/bin";

  # XDG-compliant Go paths - same values on both platforms.
  goEnvVars = {
    GOPATH = config.modules.development.go.path;
    GOMODCACHE = "$XDG_CACHE_HOME/go/mod";
    GOCACHE = "$XDG_CACHE_HOME/go-build";
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
      default = if isDarwin then "${config.xdg.dataHome}/go" else "$XDG_DATA_HOME/go";
      description = "Go workspace path used for GOPATH.";
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

    (mkIf config.modules.shell.zsh.enable {
      modules.shell.zsh.env = ''
        ${shellExports goEnvVars}
      '';
    })

    (mkIf (config.modules.shell.zsh.enable && config.modules.development.go.includeBinToPath) {
      modules.shell.zsh.env = ''
        export PATH="${goBinPath}:$PATH"
      '';
    })

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
        env.PATH = [ goBinPath ];
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
        home.sessionPath = [ goBinPath ];
      })
    ]))
  ]);
}
