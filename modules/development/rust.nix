# development/rust.nix -- https://rust-lang.org
#
# Next generation of C/C++ performatic system's programming language.
# Rust, oh Rust, the world is not ready for you yet.
#
# Linux: user.packages + env = rustEnvVars.
# Darwin: home.packages + home.sessionVariables = rustEnvVars.

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

  rustupWithoutRustAnalyzer = pkgs.runCommand "rustup-without-rust-analyzer" { } ''
    mkdir -p "$out/bin"

    for bin in ${pkgs.rustup}/bin/*; do
      ln -s "$bin" "$out/bin/$(basename "$bin")"
    done

    rm -f "$out/bin/rust-analyzer"
  '';

  rustupPackage =
    if config.modules.development.rust.languageServer.enable then
      rustupWithoutRustAnalyzer
    else
      pkgs.rustup;

  rustPackages = with pkgs; [
    nasm # assembler (used by some Rust crates with C interop)
    rustupPackage # toolchain manager (installs stable/nightly via rustup)
    zlib # compression library linked by many crates
  ];

  # XDG-compliant Rust/Cargo paths — same values on both platforms.
  rustEnvVars = {
    RUSTUP_HOME = "${config.modules.development.rust.path}/up";
    CARGO_HOME = "${config.modules.development.rust.path}/cargo";
    CARGO_TARGET_DIR = "$CARGO_HOME/target"; # shared build cache across projects
  };
in
{
  options.modules.development.rust = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    path = mkOption {
      type = with types; (either str path);
      default = if isDarwin then "${config.xdg.dataHome}/rust" else "$XDG_DATA_HOME/rust";
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

    (mkIf config.modules.shell.zsh.enable {
      modules.shell.zsh.env = shellExports rustEnvVars;
    })

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) (mkMerge [
      {
        user.packages = rustPackages;
        env = rustEnvVars;
      }

      (mkIf config.modules.development.rust.languageServer.enable {
        user.packages = with pkgs; [ rust-analyzer ];
      })

      (mkIf config.modules.development.rust.includeBinToPath {
        env.PATH = [ "$CARGO_HOME/bin" ];
      })
    ]))

    # Darwin (MacOS)
    (optionalAttrs isDarwin (mkMerge [
      {
        home.packages = rustPackages;
        home.sessionVariables = rustEnvVars;
      }

      (mkIf config.modules.development.rust.languageServer.enable {
        home.packages = with pkgs; [ rust-analyzer ];
      })

      (mkIf config.modules.development.rust.includeBinToPath {
        home.sessionPath = [ "$CARGO_HOME/bin" ];
      })
    ]))
  ]);
}
