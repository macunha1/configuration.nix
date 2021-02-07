# hosts/nixosmos/boot.nix -- Boot Configuration (GRUB)

{ config, lib, pkgs, ... }:

{
  boot.initrd = {
    availableKernelModules = [ "usbhid" "usb_storage" "sr_mod" ];
    kernelModules = [ ];
  };

  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.kernelParams = [ "console=ttyAMA0,115200" "console=tty1" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.cleanTmpDir = true;
  boot.loader = {
    # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
    grub.enable = false;
    # Enables the generation of /boot/extlinux/extlinux.conf
    generic-extlinux-compatible.enable = true;
  };
}
