# development/rust.nix -- https://rust-lang.org
#
# Next generation of C/C++ performatic system's programming language.
# Rust, oh Rust, the world is not ready for you yet.
#
{
  config,
  options,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
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
    platformPath
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

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
    llvmPackages.libclang.lib # libclang shared library used by bindgen-based crates
    llvmPackages.llvm.dev # llvm-config and LLVM development metadata

    nasm # assembler (used by some Rust crates with C interop)
    rustupPackage # toolchain manager (installs stable/nightly via rustup)
    zlib # compression library linked by many crates
  ];

  # XDG-compliant Rust/Cargo paths — same values on both platforms.
  rustEnvVars = {
    RUSTUP_HOME = "${config.modules.development.rust.path}/up";
    CARGO_HOME = "${config.modules.development.rust.path}/cargo";
    CARGO_TARGET_DIR = "${config.modules.development.rust.path}/cargo/target";

    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
    LLVM_CONFIG_PATH = "${pkgs.llvmPackages.llvm.dev}/bin/llvm-config";
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
      default = xdg.concrete.data "rust";
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
    (platformPackages {
      inherit isDarwin;
      packages = rustPackages;
    })

    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = rustEnvVars;
      target = "both";
    })

    (mkIf config.modules.development.rust.languageServer.enable (platformPackages {
      inherit isDarwin;
      packages = with pkgs; [ rust-analyzer ];
    }))

    (mkIf config.modules.development.rust.includeBinToPath (platformPath {
      inherit config isDarwin;
      paths = [ "${config.modules.development.rust.path}/cargo/bin" ];
      target = "both";
    }))
  ]);
}
