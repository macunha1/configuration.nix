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

  inherit (lib.my or (import ../../lib/modules.nix { inherit lib; }))
    platformEnv
    platformPackages
    platformPath
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  goBinPath = "${config.modules.development.go.path}/bin";

  # XDG-compliant Go paths - same values on both platforms.
  goEnvVars = {
    GOPATH = config.modules.development.go.path;
    GOMODCACHE = xdg.shell.cache "go/mod";
    GOCACHE = xdg.shell.cache "go-build";
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
      default = xdg.concrete.data "go";
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
    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = goEnvVars;
      darwinTarget = "both";
    })

    (mkIf (config.modules.shell.zsh.enable && config.modules.development.go.includeBinToPath) {
      modules.shell.zsh.env = ''
        export PATH="${goBinPath}:$PATH"
      '';
    })

    (mkIf config.modules.development.go.includeBinToPath (platformPath {
      inherit config isDarwin;
      paths = [ goBinPath ];
      darwinTarget = "session";
    }))

    (mkIf config.modules.development.go.languageServer.enable (platformPackages {
      inherit isDarwin;
      packages = with pkgs; [ gopls ];
    }))

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = with pkgs; [
        libcap # Linux-only: POSIX capabilities (used by some Go tools)
        go
      ];
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      home.packages = with pkgs; [ go ];
    })
  ]);
}
