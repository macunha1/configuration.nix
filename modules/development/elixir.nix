# development/elixir.nix -- https://elixir-lang.org/
#
# Erlang taken to the next level. Or is it a better Ruby?

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

  elixirPackages = with pkgs.beamPackages; [
    elixir
    erlang # exposes erl/escript for Mix dependencies compiled through rebar3
  ];

  elixirEnvVars = {
    MIX_HOME = config.modules.development.elixir.mix.path;
    HEX_HOME = config.modules.development.elixir.hex.path;
  };
in
{
  options.modules.development.elixir = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    # Elixir package manager
    mix = {
      path = mkOption {
        type = with types; (either str path);
        default = if isDarwin then "${config.xdg.dataHome}/mix" else "$XDG_DATA_HOME/mix";
      };
    };

    hex = {
      path = mkOption {
        type = with types; (either str path);
        default = if isDarwin then "${config.xdg.dataHome}/hex" else "$XDG_DATA_HOME/hex";
      };
    };
  };

  config = mkIf config.modules.development.elixir.enable (mkMerge [
    (mkIf config.modules.shell.zsh.enable {
      modules.shell.zsh.env = shellExports elixirEnvVars;
    })

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = elixirPackages;
      env = elixirEnvVars;
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      home.packages = elixirPackages;
      home.sessionVariables = elixirEnvVars;
    })
  ]);
}
