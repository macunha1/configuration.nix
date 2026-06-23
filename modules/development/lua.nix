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
#
# Linux: installed as user packages.
# Darwin: installed as home packages.
# jit.enable: picks LuaJIT over the reference interpreter (default = !lua.enable).
# includeBinToPath: luarocks path injected into zsh.init on both platforms.

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
  # Interpreter: reference Lua or LuaJIT - mutually exclusive, both provide
  # bin/lua so only one can live in the same package environment at a time.
  interpreter = if config.modules.development.lua.jit.enable then pkgs.luajit else pkgs.lua;

  # Base packages - chosen interpreter + luarocks, same on both platforms.
  basePkgs = [
    interpreter
    pkgs.luarocks
  ];
in
{
  options.modules.development.lua = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    jit = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Use LuaJIT instead of the reference Lua interpreter.
          Defaults to the opposite of modules.development.lua.enable:
          when lua is first enabled the reference interpreter is selected;
          set this to true to opt into LuaJIT.
        '';
      };
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

  config = mkMerge [

    # Dynamic default: jit.enable starts as the opposite of lua.enable so that
    # enabling lua for the first time selects the reference interpreter.
    # The user can explicitly set jit.enable = true to opt into LuaJIT.
    {
      modules.development.lua.jit.enable = mkDefault (!config.modules.development.lua.enable);
    }

    (mkIf config.modules.development.lua.enable (mkMerge [

      # Linux (NixOS)
      (optionalAttrs (!isDarwin) (mkMerge [
        { user.packages = basePkgs; }

        (mkIf config.modules.development.lua.languageServer.enable {
          user.packages = [ pkgs.luaPackages.lua-lsp ];
        })
      ]))

      # Darwin (MacOS)
      (optionalAttrs isDarwin (mkMerge [
        { home.packages = basePkgs; }

        (mkIf config.modules.development.lua.languageServer.enable {
          home.packages = [ pkgs.luaPackages.lua-lsp ];
        })
      ]))

      # Both platforms: prepend luarocks bin dir to PATH via zsh init.
      (mkIf config.modules.development.lua.includeBinToPath {
        modules.shell.zsh.init = ''eval "$(luarocks path --bin)"'';
      })
    ]))
  ];
}
