# development/python.nix -- https://godotengine.org/
#
# Python was the main igniter for using NixOS, the mess with minor versions
# updates breaking system dependencies, packages and creating a dependency hell
# drives me mad.

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.development.python = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.development.python.enable {
    user.packages = with pkgs; [
      python39Full

      # Dependency (package) management
      python39Packages.pip
      pipenv # spin virtual envs like a god

      python39Packages.autopep8 # pep8 prettify
      python39Packages.flake8 # code lint
      python39Packages.setuptools # distutils++
    ];

    env.PYTHONSTARTUP = "$XDG_CONFIG_HOME/python/pythonrc";
    env.PYTHON_EGG_CACHE = "$XDG_CACHE_HOME/python-eggs";
    env.FLAKE8_CONFIG_FILE = "$XDG_CONFIG_HOME/flake8";
    env.PIP_CONFIG_FILE = "$XDG_CONFIG_HOME/pip/pip.conf";
    env.PIP_LOG_FILE = "$XDG_DATA_HOME/pip/log";

    environment.shellAliases = {
      py = "python";
      py2 = "python2";
      py3 = "python3";
    };
  };
}
