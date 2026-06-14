# packages/helm.nix -- https://helm.sh/
#
# Latest stable Helm binary package. This intentionally uses upstream release
# tarballs so the Kubernetes module can move faster than the pinned nixpkgs
# source build when a small Helm patch release lands.

{ lib
, stdenv
, fetchurl
, installShellFiles
, kubernetes-helm
}:

let
  version = "4.2.1";

  platform = {
    x86_64-linux = {
      name = "linux-amd64";
      hash = "sha256-R53Kg25bRei9IiQAxVkbDjpkc3jwP/lllxgNuXwX/a4=";
    };
    aarch64-linux = {
      name = "linux-arm64";
      hash = "sha256-WWuac9Nmwecs5n1ZXCKAVIDjCRRZOq+8n1R2lOcoFNs=";
    };
    x86_64-darwin = {
      name = "darwin-amd64";
      hash = "sha256-KiHJ82jWCLz263lOvAZRTra1KahGtg/kpD3qe8zmUig=";
    };
    aarch64-darwin = {
      name = "darwin-arm64";
      hash = "sha256-iWRy0uwHQMYPZKnfD8MNR4vu44oaKm7ZGqbm7hd8FXU=";
    };
  }.${stdenv.hostPlatform.system} or (throw
    "Unsupported Helm platform: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "kubernetes-helm";
  inherit version;

  src = fetchurl {
    url = "https://get.helm.sh/helm-v${version}-${platform.name}.tar.gz";
    inherit (platform) hash;
  };

  sourceRoot = ".";
  nativeBuildInputs = [ installShellFiles ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ${platform.name}/helm "$out/bin/helm"
  ''
  + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    "$out/bin/helm" completion bash > helm.bash
    "$out/bin/helm" completion zsh > helm.zsh
    "$out/bin/helm" completion fish > helm.fish
    installShellCompletion helm.{bash,zsh,fish}
  ''
  + ''
    runHook postInstall
  '';

  meta = kubernetes-helm.meta // {
    mainProgram = "helm";
  };
}
