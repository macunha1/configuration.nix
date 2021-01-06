{ config, ... }:

{
  networking.hostName = "nixbox";

  # DEPRECATED: therefore, explicitly set to false
  networking.useDHCP = false;

  networking.interfaces.ens6 = {
    ipv4.addresses = [{
      address = "192.168.50.4";
      prefixLength = 24;
    }];
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  networking.firewall = {
    # enable = false;
    # checkReversePath = false;

    # allowedUDPPorts = [ ... ];
    # allowedTCPPorts = [ ... ];
  };
}
