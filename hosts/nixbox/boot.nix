{ lib, pkgs, ... }:

{
  boot = {
    initrd = {
      availableKernelModules = [
        "ata_piix"
        "virtio_pci"
        "floppy"
        "sd_mod"
        "sr_mod"
      ];
      kernelModules = [ ];
    };

    # Use the latest kernel
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ ];
    extraModulePackages = [ ];

    # NOTE: GRUB might cause issues with Vagrant
    # loader.grub = {
    #   enable = true;
    #   version = 2;
    # };
    loader = {
      efi.canTouchEfiVariables = lib.mkDefault true;

      systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = lib.mkDefault 5;
      };
    };
  };
}
