{ config, ... }:

{
  boot.initrd = {
    availableKernelModules =
      [ "ata_piix" "virtio_pci" "floppy" "sd_mod" "sr_mod" ];

    kernelModules = [ ];
  };

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
