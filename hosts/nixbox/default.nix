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

  nix = {
    settings.max-jobs = lib.mkDefault 4;

    # Automatic collect garbage to save disk space (which is very limited)
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}
