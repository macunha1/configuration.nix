# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports =
    [
      <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
      ./networking.nix
      ./file-systems.nix
      ./modules.nix
    ];

  # Boot Configuration (GRUB)
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

  # Bluetooth
  hardware.bluetooth.enable = true;

  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };

  services.blueman.enable = true;

  # GPU and Graphics
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override {
      enableHybridCodec = true;
    };
  };

  nixpkgs.config.allowUnfree = true; # necessary evil

  hardware.opengl = {
    enable = true;
    setLdLibraryPath = true;
    driSupport32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  environment.systemPackages = with pkgs; [
    # OS basics
    pavucontrol

    # TODO: Create the LY overlay to support DM, systemctl missing
    ly

    # TODO: Convert into module, using the lockscreen script
    i3lock

    # CLI Tools and Utils
    rofi  # TUI all the things

    scrot # Lightweight screenshooter
    feh   # Simple image viewer

    # Infra/Cloud
    kubectl
    helm
    awscli
    # google-cloud-sdk
    # aws-iam-authenticator
  ];

  nix.maxJobs = lib.mkDefault 8;
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  hardware.cpu.intel.updateMicrocode = true;
}
