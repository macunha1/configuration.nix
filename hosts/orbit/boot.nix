# hosts/nixosmos/boot.nix -- Boot Configuration (GRUB)

_:

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

    kernelParams = [
      "8250.nr_uarts=1"
      "console=ttyAMA0,115200"
      "console=tty1"

      # A lot GUI programs need this, nearly all wayland applications
      "cma=128M"
    ];

    tmp = {
      cleanOnBoot = true;
      useTmpfs = true;
    };

    loader.grub.enable = false;
  };
}
