{ config, lib, pkgs, ... }:

{
  boot.initrd = {
    availableKernelModules =
      [ "ata_piix" "virtio_pci" "floppy" "sd_mod" "sr_mod" ];

    kernelModules = [ ];
  };

  # Use the latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # NOTE: GRUB might cause issues with Vagrant
  # boot.loader = {
  #   grub = {
  #     enable = true;
  #     version = 2;
  #   };
  # };

  boot.loader = {
    efi.canTouchEfiVariables = lib.mkDefault true;

    systemd-boot = {
      enable = lib.mkDefault true;
      configurationLimit = lib.mkDefault 10;
    };
  };

}
