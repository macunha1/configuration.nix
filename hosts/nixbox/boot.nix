{ config, pkgs, ... }:

{
  boot.initrd = {
    availableKernelModules =
      [ "ata_piix" "virtio_pci" "floppy" "sd_mod" "sr_mod" ];

    kernelModules = [ ];
  };

  # Use the latest kernel
  boot.kernelPackages = pkgs.linuxPackages_5_9;

  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # NOTE: GRUB might cause issues with Vagrant
  # boot.loader = {
  #   grub = {
  #     enable = true;
  #     version = 2;
  #   };
  # };
}
