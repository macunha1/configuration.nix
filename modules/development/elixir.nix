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

  inherit (lib.my or (import ../../lib/modules.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

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
        default = xdg.concrete.data "mix";
      };
    };

    hex = {
      path = mkOption {
        type = with types; (either str path);
        default = xdg.concrete.data "hex";
      };
    };
  };

  config = mkIf config.modules.development.elixir.enable (mkMerge [
    (platformPackages {
      inherit isDarwin;
      packages = elixirPackages;
    })

    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = elixirEnvVars;
      darwinTarget = "both";
    })
  ]);
}
