{ pkgs ? import <nixpkgs> { } }:

with pkgs;
let
  nixBin = writeShellScriptBin "nix" ''
    ${nixVersions.stable}/bin/nix --option experimental-features "nix-command flakes" "$@"
  '';
in mkShell {
  buildInputs = [ git home-manager cachix ];
  shellHook = ''
    export PATH="$(pwd)/bin:${nixBin}/bin:$PATH"
  '';
}
