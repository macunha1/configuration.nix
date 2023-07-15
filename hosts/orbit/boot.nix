# hosts/nixosmos/boot.nix -- Boot Configuration (GRUB)

{ config, lib, pkgs, ... }:

{
  boot.initrd = {
    availableKernelModules =
      [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];

    kernelModules = [ ];
  };

  boot.kernelPackages = pkgs.linuxPackages_rpi4;
  boot.kernelParams = [
    "8250.nr_uarts=1"
    "console=ttyAMA0,115200"
    "console=tty1"

    # A lot GUI programs need this, nearly all wayland applications
    "cma=128M"
  ];

  boot.tmp = {
    cleanOnBoot = true;
    useTmpfs = true;
  };

  boot.loader = {
    raspberryPi = {
      enable = lib.mkDefault true;
      version = 4;
    };

    grub.enable = false;
  };
}
