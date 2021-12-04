# development/lua.nix -- https://www.lua.org/
#
# Lua stands for "Moon" in Portuguese (surprise! Lua is a Brazilian language)
# (surprise again in case you thought people speak Spanish in Brazil).
#
# Moon is the natural satellite of Earth. Lua acts as the perfect satellite
# language for systems programming languages (e.g. C/C++).
#
# Personally speaking, Lua is mostly used on this setup for AwesomeWM and
# performance-critical scripting scenarios.

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.development.lua = {
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

    (mkIf config.modules.development.lua.languageServer.enable {
      user.packages = with pkgs; [ luaPackages.lua-lsp ];
    })

    (mkIf config.modules.development.lua.includeBinToPath {
      modules.shell.zsh.init = ''eval "$(luarocks path --bin)"'';
    })
  ]);
}
