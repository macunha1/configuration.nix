{ lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"

    ./boot.nix
    ./file-systems.nix
    ./modules.nix
    ./networking.nix
  ];

  time.timeZone = "Etc/UTC";
  nix.maxJobs = lib.mkDefault 4;
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}
