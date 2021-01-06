{ modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"

    ./boot.nix
    ./file-systems.nix
    ./modules.nix
    ./networking.nix
  ];

  time.timeZone = "Etc/UTC";
}
