# development/elixir.nix -- https://elixir-lang.org/
#
# Erlang taken to the next level.

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.development.elixir = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    mix = {
      path = mkOption {
        type = with types; (either str path);
        default = "$XDG_DATA_HOME/mix";
      };
    };
  };

  config = mkIf config.modules.development.elixir.enable {
    user.packages = with pkgs; [ elixir ];

    env.MIX_HOME = config.modules.development.elixir.mix.path;
  };
}
