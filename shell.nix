{ pkgs ? import <nixpkgs> { } }:

with pkgs;
let
  nixBin = writeShellScriptBin "nix" ''
    ${nixFlakes}/bin/nix --option experimental-features "nix-command flakes" "$@"
  '';
in mkShell {
  buildInputs = [ git ];
  shellHook = ''
    export PATH="$(pwd)/bin:${nixBin}/bin:$PATH"
  '';
}
