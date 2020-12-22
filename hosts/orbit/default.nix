{ config, lib, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>

    ./boot.nix
    ./networking.nix
    ./file-systems.nix
    ./modules.nix
  ];

  # Required for the Wireless firmware
  hardware.enableRedistributableFirmware = true;

  # Audio & Media control
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };

  environment.systemPackages = with pkgs; [
    raspberrypi-tools
    pavucontrol
    patchelf
    nix-prefetch-git
    nix-prefetch
  ];

  # Bluetooth (especially for audio)
  hardware.bluetooth.enable = true;

  services.blueman.enable = true;
  services.dbus.packages = with pkgs; [ blueman ];

  # Bluetooth device proxy for media control
  my.home.systemd.user.services.mpris-proxy = {
    Unit.Description = "Mpris proxy";
    Unit.After = [ "network.target" "sound.target" ];
    Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    Install.WantedBy = [ "default.target" ];
  };

  # GPU and Graphics
  nixpkgs.config.allowUnfree = true; # necessary evil

  hardware.opengl = {
    enable = true;
    setLdLibraryPath = true;
    driSupport32Bit = true;
  };

  services.xserver = {
    layout = "us";
    xkbVariant = "intl";
  };

  my.home.xdg = {
    cacheHome = "/home/${config.my.username}/.cache";
    configHome = "/home/${config.my.username}/.config";
    dataHome = "/home/${config.my.username}/.local/share";
  };

  time.timeZone = "Europe/Berlin";
  my.user.extraGroups = [ "networkmanager" ];

  nix = {
    maxJobs = lib.mkDefault 4;

    # Automatic collect garbage to save disk space (which is very limited)
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
  };
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
