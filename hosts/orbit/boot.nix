# hosts/nixosmos/boot.nix -- Boot Configuration (GRUB)

{ config, lib, pkgs, ... }:

{
  boot.initrd = {
    availableKernelModules =
      [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];

    kernelModules = [ ];
  };

  boot.kernelParams = [ "console=ttyAMA0,115200" "console=tty1" ];
  boot.kernelPackages = pkgs.linuxPackages_rpi4;

  boot.cleanTmpDir = true;
  boot.loader = {
    raspberryPi = {
      enable = true;
      version = 4;
      uboot.enable = true;
    };

    grub.enable = false;
  };
}
