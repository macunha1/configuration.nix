{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    ./boot.nix
    ./networking.nix
    ./file-systems.nix
    ./modules.nix
  ];

  # GPU and Graphics
  nixpkgs.config = {
    packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    };

    allowUnfree = true; # necessary evil
  };

  services.xserver = {
    layout = "us";
    xkbVariant = "intl";
  };

  time.timeZone = "Europe/Berlin";
  user.extraGroups = [ "networkmanager" ];

  nix.maxJobs = lib.mkDefault 8;
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  hardware.cpu.intel.updateMicrocode = true;
}
