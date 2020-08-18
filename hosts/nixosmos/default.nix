{ config, lib, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>

    ./boot.nix
    ./networking.nix
    ./file-systems.nix
    ./modules.nix
  ];

  # Audio & Media control
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };

  environment.systemPackages = with pkgs; [ pavucontrol ];

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
  nixpkgs.config = {
    packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override {
        enableHybridCodec = true;
      };
    };

    allowUnfree = true; # necessary evil
  };

  hardware.opengl = {
    enable = true;
    setLdLibraryPath = true;
    driSupport32Bit = true;
  };

  services.xserver = {
    videoDrivers = [ "nvidia" ];
    layout = "us";
    xkbVariant = "intl";
  };

  my.home.xdg = {
    configHome = "/home/${config.my.username}/.config";
    cacheHome  = "/home/${config.my.username}/.cache";
    dataHome   = "/home/${config.my.username}/.local/share";
  };

  time.timeZone = "Europe/Berlin";
  my.user.extraGroups = [ "networkmanager" ];

  nix.maxJobs = lib.mkDefault 8;
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  hardware.cpu.intel.updateMicrocode = true;
}
