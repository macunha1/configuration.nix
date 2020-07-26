# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>

    ./boot.nix
    ./networking.nix
    ./file-systems.nix
    ./modules.nix
  ];

  # Bluetooth (especially for audio)
  hardware.bluetooth.enable = true;

  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };

  services.blueman.enable = true;

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

  services.xserver.videoDrivers = [ "nvidia" ];

  environment.systemPackages = with pkgs; [
    # OS basics
    pavucontrol

    # TODO: Create the Ly overlay adding support for systemctl
    ly

    # DEA: Data Engineering and Analytics
    # ICE: Infrastructure and Cloud Engineering
    kubectl
    helm

    awscli
    aws-iam-authenticator

    google-cloud-sdk
  ];

  nix.maxJobs = lib.mkDefault 8;
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  hardware.cpu.intel.updateMicrocode = true;
}
