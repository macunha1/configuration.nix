# development/python.nix -- https://www.python.org/
#
# Python was the main igniter for using NixOS, the mess with minor versions
# updates breaking system dependencies, packages and creating a dependency hell
# drives me insane.

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

  pythonPackageManagers = {
    uv = pkgs.uv;
  };

  pythonPackageManagerPackage =
    pythonPackageManagers.${config.modules.development.python.packageManager};

  pythonPackages = with pkgs; [
    python3

    python3Packages.pip # package installer
    pythonPackageManagerPackage # Python tool manager

    python3Packages.pytest # test runner
    python3Packages.autopep8 # pep8 prettify
    python3Packages.flake8 # code lint
    python3Packages.setuptools # distutils++
  ];

  # XDG-compliant Python paths - shared by Linux env and generated ZSH.
  pythonEnvVars = {
    PYTHONSTARTUP = xdg.shell.config "python/pythonrc";
    PYTHON_EGG_CACHE = xdg.shell.cache "python-eggs";
    FLAKE8_CONFIG_FILE = xdg.shell.config "flake8";
    PIP_CONFIG_FILE = xdg.shell.config "pip/pip.conf";
    PIP_LOG_FILE = xdg.shell.data "pip/log";
  };

  # Shell aliases - identical on both platforms; only the option name differs.
  pythonAliases = {
    python = "python3";
    py = "python";
    py2 = "python2";
    py3 = "python3";
  };
in
{
  options.modules.development.python = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

    packageManager = mkOption {
      type = types.enum (attrNames pythonPackageManagers);
      default = "uv";
      description = "Python package and tool manager to install.";
    };

    packageManagerCommand = mkOption {
      type = types.str;
      default = config.modules.development.python.packageManager;
      description = "Command used to run the configured Python package manager.";
    };

    languageServer = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf config.modules.development.python.enable (mkMerge [
    (platformPackages {
      inherit isDarwin;
      packages = pythonPackages;
    })

    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = pythonEnvVars;
      darwinTarget = "zsh";
    })

    (mkIf config.modules.development.python.languageServer.enable (platformPackages {
      inherit isDarwin;
      packages = with pkgs; [ zuban ];
    }))

    (optionalAttrs (!isDarwin) {
      environment.shellAliases = pythonAliases;
    })

    (optionalAttrs isDarwin {
      modules.shell.zsh.aliases = pythonAliases;
    })
  ]);
}
