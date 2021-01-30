# hosts/nixosmos/boot.nix -- Boot Configuration (GRUB)

{ config, lib, pkgs, ... }:

{
  boot.initrd = {
    availableKernelModules =
      [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];

    kernelModules = [ ];
  };

  # Use the latest kernel
  boot.kernelPackages = pkgs.linuxPackages_5_10;

  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
}
