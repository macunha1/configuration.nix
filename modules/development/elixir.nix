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
  elixirPackages = with pkgs; [
    elixir
    erlang # exposes erl/escript for Mix dependencies compiled through rebar3
  ];

  elixirEnvVars = {
    MIX_HOME = config.modules.development.elixir.mix.path;
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
        default = "$XDG_DATA_HOME/mix";
      };
    };
  };

  config = mkIf config.modules.development.elixir.enable (mkMerge [

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
