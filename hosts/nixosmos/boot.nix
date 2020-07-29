# hosts/nixosmos/boot.nix -- Boot Configuration (GRUB)

{ config, lib, pkgs, ... }:

{
  boot.initrd = {
    availableKernelModules = [
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];

    kernelModules = [ ];
  };

  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.loader = {
    efi = {
      canTouchEfiVariables = false;
    };

    grub = {
      enable = true;
      efiSupport = true;
      version = 2;
      device = "nodev";
      useOSProber = true;
    };
  };
}