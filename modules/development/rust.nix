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

    path = mkOption {
      type = with types; (either str path);
      default = "$XDG_DATA_HOME/rust";
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

  config = mkIf config.modules.development.rust.enable (mkMerge [
    {
      user.packages = with pkgs; [ nasm rustup zlib rustfmt ];

      env.RUSTUP_HOME = "${config.modules.development.rust.path}/up";
      env.CARGO_HOME = "${config.modules.development.rust.path}/cargo";
      env.CARGO_TARGET_DIR = "$CARGO_HOME/target";
    }

    (mkIf config.modules.development.rust.languageServer.enable {
      user.packages = with pkgs; [ rust-analyzer ];
    })

    (mkIf config.modules.development.rust.includeBinToPath {
      env.PATH = [ "$CARGO_HOME/bin" ];
    })
  ]);
}
