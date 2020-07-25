# modules/dev/lua.nix --- https://www.lua.org/
#
# Lua is Moon in Portuguese, the natural satellite of Earth. Acting as the
# perfect satellite language for system's programming languages.
# Mainly used for AwesomeWM and performance-critical scenarios.

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.dev.lua = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.dev.lua.enable {
    my = {
      packages = with pkgs; [
        lua
        luajit
        luaPackages.moonscript
        luarocks
      ];

      zsh.rc = ''eval "$(luarocks path --bin)"'';
    };
  };
}
