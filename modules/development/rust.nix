# modules/development/rust.nix --- https://rust-lang.org

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.development.rust = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.rust.enable {
    my = {
      packages = with pkgs; [
        rustup
      ];

      env.RUSTUP_HOME = "$XDG_DATA_HOME/rustup";
      env.CARGO_HOME = "$XDG_DATA_HOME/cargo";
      env.PATH = [ "$CARGO_HOME/bin" ];

      alias.rs  = "rustc";
      alias.rsp = "rustup";
      alias.ca  = "cargo";
    };
  };
}
