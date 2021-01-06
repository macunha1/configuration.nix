# modules/development/lua.nix --- https://www.lua.org/
#
# Lua is Moon in Portuguese, the natural satellite of Earth. Acting as the
# perfect satellite language for system's programming languages.
# Mainly used for AwesomeWM and performance-critical scenarios.

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.development.lua = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

    includeBinToPath = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.lua.enable (mkMerge [
    {
      user.packages = with pkgs; [
        # Interpreters
        lua
        luajit

        # Dependency/package management
        luarocks
      ];
    }

    (mkIf config.modules.development.lua.includeBinToPath {
      zsh.rc = ''eval "$(luarocks path --bin)"'';
    })
  ]);
}
