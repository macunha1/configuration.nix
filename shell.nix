let
  # Ref: https://nixos.wiki/wiki/FAQ/Pinning_Nixpkgs
  nixpkgs = builtins.fetchTarball {
    name = "nixpkgs-5abe06c";
    url = "https://github.com/NixOS/nixpkgs/archive/5abe06c.tar.gz";
    sha256 = "0mqwd5psp2g9bxp0hd3mja8dkfdxkaqqbw311q46kxw1pcbzsmbl";
  };

in { pkgs ? import nixpkgs { } }:

with pkgs;
let
  nixBin = writeShellScriptBin "nix" ''
    ${nixFlakes}/bin/nix --option experimental-features "nix-command flakes" "$@"
  '';
in mkShell {
  buildInputs =
    [ git home-manager cachix dhall-json haskellPackages.dhall-yaml ];
  shellHook = ''
    export PATH="$(pwd)/bin:${nixBin}/bin:$PATH"
  '';
}
