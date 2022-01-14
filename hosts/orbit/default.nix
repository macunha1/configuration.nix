{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    ./boot.nix
    ./networking.nix
    ./file-systems.nix
    ./modules.nix
  ];

  # Required for the Wireless firmware
  hardware.enableRedistributableFirmware = true;

  # Audio & Media control
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };

  environment.systemPackages = with pkgs; [ raspberrypi-tools ];

  services.xserver = {
    layout = "us";
    xkbVariant = "intl";
  };

  time.timeZone = "Europe/Berlin";
  user.extraGroups = [ "networkmanager" ];

  nix = {
    settings.max-jobs = lib.mkDefault 4;

    # Automatic collect garbage to save disk space (which is very limited)
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
