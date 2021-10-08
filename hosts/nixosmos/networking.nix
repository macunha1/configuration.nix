{ config, pkgs, ... }:

{
  networking.hostName = "nixosmos";
  networking.networkmanager.enable = true;

  networking.nameservers = [
    # CloudFlare DNS
    "1.1.1.1"

    # Google DNS (fallback)
    "8.8.8.8"
  ];

  # DHCP
  networking.useDHCP = false; # DEPRECATED: therefore, explicitly set to false
  networking.interfaces = {
    # Per-interface useDHCP is the new black
    enp0s31f6.useDHCP = true;
    wlp4s0.useDHCP = true;
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  networking.firewall = {
    enable = true;
    checkReversePath = false;

    # allowedUDPPorts = [ ... ];
    # allowedTCPPorts = [ ... ];
  };
}
