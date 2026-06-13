# development/python.nix -- https://www.python.org/
#
# Python was the main igniter for using NixOS, the mess with minor versions
# updates breaking system dependencies, packages and creating a dependency hell
# drives me mad.
#
# Python 3.14 (python311Full removed; tkinter and Bluetooth are now always included).
# Linux: user.packages + env = pythonEnvVars + environment.shellAliases.
# Darwin: home.packages + modules.shell.zsh.env = pythonEnvVars + home.shellAliases.

{ config, options, lib, pkgs, isDarwin ? pkgs.stdenv.isDarwin, ... }:

with lib;

let
  pythonPackages = with pkgs; [
    python314

    python314Packages.pip    # package installer
    pipenv                   # spin virtual envs like a god

    python314Packages.pytest    # test runner
    python314Packages.autopep8  # pep8 prettify
    python314Packages.flake8    # code lint
    python314Packages.setuptools # distutils++
  ];

  # XDG-compliant Python paths - same values on both platforms.
  pythonEnvVars = {
    PYTHONSTARTUP      = "$XDG_CONFIG_HOME/python/pythonrc";
    PYTHON_EGG_CACHE   = "$XDG_CACHE_HOME/python-eggs";
    FLAKE8_CONFIG_FILE = "$XDG_CONFIG_HOME/flake8";
    PIP_CONFIG_FILE    = "$XDG_CONFIG_HOME/pip/pip.conf";
    PIP_LOG_FILE       = "$XDG_DATA_HOME/pip/log";
  };

  # Shell aliases - identical on both platforms; only the option name differs.
  pythonAliases = {
    py  = "python";
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

    languageServer = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf config.modules.development.python.enable (mkMerge [

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) (mkMerge [
      {
        user.packages = pythonPackages;
        env = pythonEnvVars;
        environment.shellAliases = pythonAliases;
      }

      (mkIf config.modules.development.python.languageServer.enable {
        user.packages = with pkgs; [ python314Packages.jedi ];
      })
    ]))

    # Darwin (MacOS)
    (optionalAttrs isDarwin (mkMerge [
      {
        home.packages = pythonPackages;
        modules.shell.zsh.env = ''
          export PYTHONSTARTUP="${config.xdg.configHome}/python/pythonrc"
          export PYTHON_EGG_CACHE="${config.xdg.cacheHome}/python-eggs"
          export FLAKE8_CONFIG_FILE="${config.xdg.configHome}/flake8"
          export PIP_CONFIG_FILE="${config.xdg.configHome}/pip/pip.conf"
          export PIP_LOG_FILE="${config.xdg.dataHome}/pip/log"
        '';
        modules.shell.zsh.aliases = pythonAliases;
      }

      (mkIf config.modules.development.python.languageServer.enable {
        home.packages = with pkgs; [ python314Packages.jedi ];
      })
    ]))
  ]);
}
