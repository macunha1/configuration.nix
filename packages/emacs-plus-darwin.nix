# packages/emacs-plus-darwin.nix -- https://github.com/d12frosted/homebrew-emacs-plus
#
# Pre-built macOS Emacs+ app bundle from the Homebrew cask release artifacts.
# This intentionally avoids the regular Nix Emacs build because managed macOS
# GateKeeper policy can kill every locally built Emacs binary.

{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  makeWrapper,
  darwinMajorVersion ? (if stdenvNoCC.hostPlatform.isAarch64 then "26" else "15"),
}:

let
  version = "30.2-260";
  emacsVersion = "30.2";
  buildNumber = "260";
  gccMajorVersion = "16";
  homebrewPrefix = if stdenvNoCC.hostPlatform.isAarch64 then "/opt/homebrew" else "/usr/local";

  platform =
    {
      x86_64-darwin = {
        name = "x86_64-15";
        hash = "sha256-5fwn3AkSTgWpVsBPZCQUjEsbeLXXLrIjYI3o2O7e8R0=";
      };
      "aarch64-darwin-26" = {
        name = "arm64-26";
        hash = "sha256-ue2C/FNV6JlZLoMrSMoyYl6AbypR47gw3o1NxbJsx44=";
      };
      "aarch64-darwin-15" = {
        name = "arm64-15";
        hash = "sha256-KbjuAvxeg4AdDjN/OANrqAMgTd8M2LO70dmwRFqLWos=";
      };
      "aarch64-darwin-14" = {
        name = "arm64-14";
        hash = "sha256-gNTjoq1+ASYbootEPD6kRA07E0gRJZmafSUYm6AnPXA=";
      };
    }
    .${
      if stdenvNoCC.hostPlatform.system == "aarch64-darwin" then
        "${stdenvNoCC.hostPlatform.system}-${darwinMajorVersion}"
      else
        stdenvNoCC.hostPlatform.system
    }
      or (throw "Unsupported Emacs+ Darwin platform: ${stdenvNoCC.hostPlatform.system} macOS ${darwinMajorVersion}");
in
stdenvNoCC.mkDerivation {
  pname = "emacs-plus-darwin";
  inherit version;

  src = fetchurl {
    url = "https://github.com/d12frosted/homebrew-emacs-plus/releases/download/cask-30-${buildNumber}/emacs-plus-${emacsVersion}-${platform.name}.zip";
    inherit (platform) hash;
  };

  nativeBuildInputs = [
    unzip
    makeWrapper
  ];

  sourceRoot = ".";
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications" "$out/bin" "$out/share/man/man1"
    cp -R "Emacs.app" "$out/Applications/"
    cp -R "Emacs Client.app" "$out/Applications/"

    # The bundled libgccjit retains its build-time Homebrew prefix. Resolve the
    # active GCC runtime so native compilation survives formula upgrades.
    makeWrapper "$out/Applications/Emacs.app/Contents/MacOS/Emacs" "$out/bin/emacs" \
      --prefix PATH : "${homebrewPrefix}/bin:/usr/bin:/bin" \
      --run 'emacsGccRuntime="$(gcc-${gccMajorVersion} -print-file-name=libemutls_w.a 2>/dev/null || true)"; if [ -f "$emacsGccRuntime" ]; then export LIBRARY_PATH="''${emacsGccRuntime%/*}''${LIBRARY_PATH:+:$LIBRARY_PATH}"; fi; unset emacsGccRuntime'
    ln -s "$out/Applications/Emacs.app/Contents/MacOS/bin/emacsclient" "$out/bin/emacsclient"
    ln -s "$out/Applications/Emacs.app/Contents/MacOS/bin/ebrowse" "$out/bin/ebrowse"
    ln -s "$out/Applications/Emacs.app/Contents/MacOS/bin/etags" "$out/bin/etags"
    ln -s "$out/Applications/Emacs.app/Contents/MacOS/bin/ctags" "$out/bin/emacs-ctags"

    ln -s "$out/Applications/Emacs.app/Contents/Resources/man/man1/emacs.1" "$out/share/man/man1/emacs.1"
    ln -s "$out/Applications/Emacs.app/Contents/Resources/man/man1/emacsclient.1" "$out/share/man/man1/emacsclient.1"
    ln -s "$out/Applications/Emacs.app/Contents/Resources/man/man1/ebrowse.1" "$out/share/man/man1/ebrowse.1"
    ln -s "$out/Applications/Emacs.app/Contents/Resources/man/man1/etags.1" "$out/share/man/man1/etags.1"

    runHook postInstall
  '';

  passthru = {
    inherit
      buildNumber
      darwinMajorVersion
      emacsVersion
      gccMajorVersion
      homebrewPrefix
      ;
    cask = "d12frosted/emacs-plus/emacs-plus-app";
  };

  meta = {
    description = "Pre-built Darwin-only Emacs+ app bundle with native compilation";
    homepage = "https://github.com/d12frosted/homebrew-emacs-plus";
    license = lib.licenses.gpl3Plus;
    mainProgram = "emacs";
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
