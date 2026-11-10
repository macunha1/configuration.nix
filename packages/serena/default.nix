# Locked Python packaging follows oraios/serena's flake.nix.
{
  lib,
  stdenv,
  inputs,
  callPackage,
  applyPatches,
  python311,
  makeWrapper,
  writeShellScript,
  wrapGAppsHook3,
  gobject-introspection,
  gtk3,
  libayatana-appindicator,
  runCommand,
  zuban,
  serenaSource ? inputs.serena.outPath,
}:
let
  inherit (inputs.serena.inputs) uv2nix pyproject-nix pyproject-build-systems;
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = serenaSource; };
  pyprojectHacks = callPackage pyproject-nix.build.hacks { };
  patchedSource = applyPatches {
    name = "serena-managed-source";
    src = serenaSource;
    patches = [
      ./managed-config.patch
      ./managed-registration.patch
    ];
    postPatch = ''
      install -m 0644 ${./managed_servers.py} src/solidlsp/managed_servers.py
    '';
  };
  pythonSet = (callPackage pyproject-nix.build.packages { python = python311; }).overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.default
      (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
      (final: prev: {
        serena-agent = prev.serena-agent.overrideAttrs (_: {
          src = patchedSource;
        });
        ruamel-yaml-clib = prev.ruamel-yaml-clib.overrideAttrs (previousAttrs: {
          nativeBuildInputs = (previousAttrs.nativeBuildInputs or [ ]) ++ [ final.setuptools ];
        });
        proxy-tools = prev.proxy-tools.overrideAttrs (previousAttrs: {
          nativeBuildInputs = (previousAttrs.nativeBuildInputs or [ ]) ++ [ final.setuptools ];
        });
        pywebview = prev.pywebview.overrideAttrs (previousAttrs: {
          nativeBuildInputs = (previousAttrs.nativeBuildInputs or [ ]) ++ [
            final.setuptools
            final.setuptools-scm
          ];
        });
      })
      (
        _final: prev:
        lib.optionalAttrs stdenv.hostPlatform.isLinux {
          pycairo = pyprojectHacks.nixpkgsPrebuilt {
            from = python311.pkgs.pycairo;
            prev.passthru = {
              dependencies = { };
              optional-dependencies = { };
              dependency-groups = { };
            };
          };
          pygobject3 = pyprojectHacks.nixpkgsPrebuilt {
            from = python311.pkgs.pygobject3;
            prev.passthru = {
              dependencies.pycairo = [ ];
              optional-dependencies = { };
              dependency-groups = { };
            };
          };
          # pystray discovers GI at runtime, outside its wheel metadata.
          pystray = prev.pystray.overrideAttrs (previousAttrs: {
            passthru = (previousAttrs.passthru or { }) // {
              dependencies = (previousAttrs.passthru.dependencies or { }) // {
                pygobject3 = [ ];
              };
            };
          });
        }
      )
    ]
  );
  runtime = pythonSet.mkVirtualEnv "serena-env" workspace.deps.default;
  requiredRegistration = writeShellScript "serena-required-registration" ''
    set -e
    if [[ -n "''${SERENA_LANGUAGE_SERVERS:-}" ]]; then
      exec ${runtime}/bin/python -c \
        'from solidlsp.ls_config import LanguageServerRegistry; LanguageServerRegistry.get_instance()'
    fi
  '';
  testEnvironment = pythonSet.mkVirtualEnv "serena-test-env" (
    workspace.deps.default // { pytest = [ ]; }
  );
in
stdenv.mkDerivation (finalAttrs: {
  pname = "serena";
  version =
    (builtins.fromTOML (builtins.readFile (serenaSource + "/pyproject.toml"))).project.version;
  src = serenaSource;
  dontUnpack = true;
  dontWrapGApps = true;
  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    wrapGAppsHook3
    gobject-introspection
  ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    gtk3
    libayatana-appindicator
  ];
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    # wrapGAppsHook3 also loads makeBinaryWrapper, which does not support --run.
    makeShellWrapper ${runtime}/bin/serena "$out/bin/serena" \
      --run ${lib.escapeShellArg "${requiredRegistration} || exit $?"}
    makeWrapper ${runtime}/bin/serena-hooks "$out/bin/serena-hooks"
    runHook postInstall
  '';
  preFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    wrapProgram "$out/bin/serena" "''${gappsWrapperArgs[@]}"
  '';
  passthru = {
    inherit runtime;
    tests.managed-servers =
      runCommand "serena-managed-server-checks"
        {
          nativeBuildInputs = [ testEnvironment ];
          SERENA_BIN = "${finalAttrs.finalPackage}/bin/serena";
          ZUBAN_BIN = lib.getExe zuban;
        }
        ''
          export HOME="$TMPDIR/home"
          export UV_OFFLINE=1
          mkdir -p "$HOME"
          cp -R ${./tests} tests
          chmod -R u+w tests
          cd tests
          ${testEnvironment}/bin/python -m pytest -q -p no:cacheprovider --confcutdir=. .
          touch "$out"
        '';
  };
  meta = {
    description = "Serena with immutable settings and externally managed language servers";
    homepage = "https://github.com/oraios/serena";
    license = lib.licenses.gpl3Plus;
    mainProgram = "serena";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
