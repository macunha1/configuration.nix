# development/python.nix -- https://www.python.org/
#
# Python was the main igniter for using NixOS, the mess with minor versions
# updates breaking system dependencies, packages and creating a dependency hell
# drives me insane.

{
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:

with lib;

let
  inherit (lib.my or (import ../../lib/modules/development/language-servers.nix { inherit lib; }))
    mkLanguageServerOptions
    mkLanguageServerContribution
    ;
  inherit (lib.my or (import ../../lib/generators.nix { inherit lib pkgs; }))
    shellExports
    ;

  inherit (lib.my or (import ../../lib/modules/utils.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  pythonPackageManagers = {
    inherit (pkgs) uv;
  };

  pythonPackageManagerPackage =
    pythonPackageManagers.${config.modules.development.python.packageManager};

  pythonPackages = with pkgs.python315.pkgs; [
    python

    pip # package installer
    pythonPackageManagerPackage # Python tool manager

    pytest # test runner
    autopep8 # pep8 prettify
    flake8 # code lint
    setuptools # distutils++
  ];

  # XDG-compliant Python paths; concrete on Darwin, shell-expanded on Linux.
  pythonEnvVars = {
    PYTHONSTARTUP = xdg.concrete.config "python/pythonrc";
    PYTHON_EGG_CACHE = xdg.concrete.cache "python-eggs";
    FLAKE8_CONFIG_FILE = xdg.concrete.config "flake8";
    PIP_CONFIG_FILE = xdg.concrete.config "pip/pip.conf";
    PIP_LOG_FILE = xdg.concrete.data "pip/log";
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

    packageManagerRunCommand = mkOption {
      type = types.str;
      default = "${config.modules.development.python.packageManagerCommand} tool run";
      description = "Command used to run tools with the configured Python package manager.";
    };

    languageServer = mkLanguageServerOptions {
      config = config.modules.development.python.languageServer;
      package = pkgs.zuban;
      arguments = [ "server" ];
      runtimePackages = [ pkgs.python315 ];
      environment = pythonEnvVars;
      adapter = "generic";
      extensions = [
        ".py"
        ".pyi"
      ];
      languageId = "python";
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
      target = "both";
    })

    (mkIf config.modules.development.python.languageServer.enable (mkLanguageServerContribution {
      inherit isDarwin;
      name = "python";
      server = config.modules.development.python.languageServer;
    }))

    (optionalAttrs (!isDarwin) {
      environment.shellAliases = pythonAliases;
    })

    (optionalAttrs isDarwin {
      modules.shell.zsh.aliases = pythonAliases;
    })
  ]);
}
