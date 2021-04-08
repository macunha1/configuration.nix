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
  };

  config = mkIf config.modules.development.elixir.enable {
    user.packages = with pkgs; [ elixir ];
  };
}
