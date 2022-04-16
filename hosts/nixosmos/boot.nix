# hosts/nixosmos/boot.nix -- Boot Configuration (GRUB)

{ config, lib, pkgs, ... }:

{
  boot.initrd = {
    availableKernelModules =
      [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];

    kernelModules = [ ];
  };

  # Use the latest kernel
  boot.kernelPackages = pkgs.linuxPackages_5_16;

  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Inherit the default boot loader: systemd
  # boot.loader.systemd-boot.enable = true;
}
