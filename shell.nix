{ pkgs ? import <nixpkgs> { } }:

with pkgs;
let
  inherit (import ./lib/generators.nix { lib = pkgs.lib; inherit pkgs; }) generatedFileWarning;

  nixBin = writeShellScriptBin "nix" ''
    ${generatedFileWarning { file = ./shell.nix; }}
    ${nixVersions.stable}/bin/nix --option experimental-features "nix-command flakes" "$@"
  '';
in mkShell {
  buildInputs = [ git home-manager cachix ];
  shellHook = ''
    export PATH="$(pwd)/bin:${nixBin}/bin:$PATH"
  '';
}
