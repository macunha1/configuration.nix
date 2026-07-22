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
      ignoredHosts ? [ ],
      hostSystemOverrides ? { },
      nixpkgsConfig ? { },
      nixpkgsOverlays ? [ ],
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
          nixpkgs = {
            config = nixpkgsConfig;
            overlays = nixpkgsOverlays;
          };
          networking.hostName = mkDefault (removeSuffix ".nix" (baseNameOf path));
        }
        (filterAttrs (
          n: v:
          !elem n [
            "system"
            "ignoredHosts"
            "hostSystemOverrides"
            "nixpkgsConfig"
            "nixpkgsOverlays"
          ]
        ) attrs)
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
      ignoredHosts ? [ ],
      hostSystemOverrides ? { },
      nixpkgsConfig ? { },
      nixpkgsOverlays ? [ ],
      ...
    }:
    filterAttrs (hostName: _: !(elem hostName ignoredHosts)) (
      mapModules dir (
        hostPath:
        let
          hostName = baseNameOf hostPath;
        in
        mkHost hostPath (attrs // { system = hostSystemOverrides.${hostName} or system; })
      )
    );
}
