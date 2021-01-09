# development/rust.nix -- https://rust-lang.org
#
# Next generation of C/C++ performatic system's programming language.
# Rust, oh Rust, the world is not ready for you yet.

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.development.rust = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    includeBinToPath = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.rust.enable (mkMerge [
    {
      user.packages = with pkgs; [ rustup ];

      env.RUSTUP_HOME = "$XDG_DATA_HOME/rustup";
      env.CARGO_HOME = "$XDG_DATA_HOME/cargo";
      env.CARGO_TARGET_DIR = "$CARGO_HOME/target";
    }

    (mkIf config.modules.development.rust.includeBinToPath {
      env.PATH = [ "$CARGO_HOME/bin" ];
    })
  ]);
}
