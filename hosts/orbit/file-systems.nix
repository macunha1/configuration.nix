{ config, pkgs, ... }:

# File system mount points
# Implementing the default spec from https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_4
{
  # Even the commentary was copied:
  # Assuming this is installed on top of the disk image.
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };

    "/nix/store" = {
      device = "/nix/store";
      fsType = "none";
      options = [ "bind" ];
    };
  };

  # Uncomment in case OOM becomes frequently to use swap, only as a last resort
  # swapDevices = [{
  #   device = "/swapfile";
  #   size = 2048;
  # }];
}
