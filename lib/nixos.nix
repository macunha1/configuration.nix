{
  inputs,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  defaultSystem = "x86_64-linux";

  mkHost =
    path:
    attrs@{
      system ? defaultSystem,
      ...
    }:
    nixosSystem {
      inherit system;
      specialArgs = {
        inherit lib inputs;
        isDarwin = false;
      };
      modules = [
        {
          nixpkgs.pkgs = pkgs;
          networking.hostName = mkDefault (removeSuffix ".nix" (baseNameOf path));
        }
        (filterAttrs (n: v: !elem n [ "system" ]) attrs)
        ../.
        (import path)
      ];
    };
in
{
  mapHosts =
    dir:
    attrs@{
      system ? defaultSystem,
      ...
    }:
    mapModules dir (hostPath: mkHost hostPath attrs);
}
