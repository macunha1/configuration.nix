# development/cc.nix -- http://gcc.gnu.org/
#
# C and C++ — the foundation everything else is built on.
#
# Linux: user.packages.
# Darwin: home.packages.
# languageServer: ccls appended via optionals to avoid mkIf-in-list antipattern.

{
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:

with lib;

let
  inherit (lib.my or (import ../../lib/modules/development/language-servers.nix { inherit lib; }))
    mkLanguageServerOptions
    mkLanguageServerContribution
    ;
  inherit (lib.my or (import ../../lib/modules/utils.nix { inherit lib; }))
    platformPath
    platformPackages
    ;

  # Base C/C++ toolchain — same on both platforms.
  ccPackages = with pkgs; [
    # GCC must own shared compiler names such as cc and c++ so enabling this
    # module provides GNU GCC (and its collect2) instead of another Clang shim.
    llvmPackages_latest.clang # LLVM C/C++ compiler frontend
    (lib.hiPrio gcc) # GNU C/C++ compiler
    gdb # GNU debugger
    cmake # cross-platform build system
    llvmPackages_latest.libcxx # LLVM C++ standard library
  ];
in
{
  options.modules.development.cc = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    languageServer = mkLanguageServerOptions {
      config = config.modules.development.cc.languageServer;
      package = pkgs.ccls;
      runtimePackages = [ pkgs.gcc ];
      languageId = "cpp_ccls";
    };
  };

  config = mkIf config.modules.development.cc.enable (mkMerge [
    (platformPackages {
      inherit isDarwin;
      packages = ccPackages;
    })

    # Keep the Nix toolchain ahead of external package-manager paths so `gcc`
    # consistently resolves to the module-owned GNU toolchain and collect2.
    (mkIf (isDarwin && config.modules.shell.zsh.enable) {
      modules.shell.zsh.env = mkAfter ''
        export PATH="${getBin pkgs.gcc}/bin:$PATH"
      '';
    })

    (mkIf isDarwin (platformPath {
      inherit config isDarwin;
      paths = [ "${getBin pkgs.gcc}/bin" ];
      target = "session";
    }))

    (mkIf config.modules.development.cc.languageServer.enable (mkLanguageServerContribution {
      inherit isDarwin;
      name = "cpp_ccls";
      server = config.modules.development.cc.languageServer;
    }))
  ]);
}
