_:

{
  networking = {
    hostName = "nixosmos";
    networkmanager.enable = true;

    nameservers = [
      # CloudFlare DNS
      "1.1.1.1"

      # Google DNS (fallback)
      "8.8.8.8"
    ];

    # DHCP
    useDHCP = false; # DEPRECATED: therefore, explicitly set to false
    interfaces = {
      # Per-interface useDHCP is the new black
      enp0s31f6.useDHCP = true;
      wlp4s0.useDHCP = true;
    };

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    firewall = {
      enable = true;
      checkReversePath = false;

      # allowedUDPPorts = [ ... ];
      # allowedTCPPorts = [ ... ];
    };
  };
}
