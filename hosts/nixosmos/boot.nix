# hosts/nixosmos/boot.nix -- Boot Configuration (GRUB)

{ lib, pkgs, ... }:

{
  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };

    # Use the latest kernel
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];

    loader = {
      efi.canTouchEfiVariables = lib.mkDefault true;

      # Inherit the default boot loader: systemd
      systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = lib.mkDefault 5;
      };
    };
  };
}
