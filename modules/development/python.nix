# development/python.nix -- https://www.python.org/
#
# Python was the main igniter for using NixOS, the mess with minor versions
# updates breaking system dependencies, packages and creating a dependency hell
# drives me mad.
#
# Python from nixpkgs plus `uv`.
# Linux: user.packages + env = pythonEnvVars + environment.shellAliases.
# Darwin: home.packages + modules.shell.zsh.env = pythonEnvVars + home.shellAliases.

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
  pythonPackages = with pkgs; [
    python3

    python3Packages.pip # package installer
    uv # another package installer, but faster

    python3Packages.pytest # test runner
    python3Packages.autopep8 # pep8 prettify
    python3Packages.flake8 # code lint
    python3Packages.setuptools # distutils++
  ];

  # XDG-compliant Python paths - same values on both platforms.
  pythonEnvVars = {
    PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonrc";
    PYTHON_EGG_CACHE = "${config.xdg.cacheHome}/python-eggs";
    FLAKE8_CONFIG_FILE = "${config.xdg.configHome}/flake8";
    PIP_CONFIG_FILE = "${config.xdg.configHome}/pip/pip.conf";
    PIP_LOG_FILE = "${config.xdg.dataHome}/pip/log";
  };

  pythonEnvLines = concatStringsSep "\n" (
    mapAttrsToList (name: value: ''export ${name}="${value}"'') pythonEnvVars
  );

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
        user.packages = with pkgs; [ python3Packages.jedi ];
      })
    ]))

    # Darwin (MacOS)
    (optionalAttrs isDarwin (mkMerge [
      {
        home.packages = pythonPackages;
        modules.shell.zsh.env = pythonEnvLines;
        modules.shell.zsh.aliases = pythonAliases;
      }

      (mkIf config.modules.development.python.languageServer.enable {
        home.packages = with pkgs; [ python3Packages.jedi ];
      })
    ]))
  ]);
}
