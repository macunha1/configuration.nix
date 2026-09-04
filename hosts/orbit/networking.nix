_:

{
  networking = {
    hostName = "orbit";
    networkmanager.enable = true;

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
