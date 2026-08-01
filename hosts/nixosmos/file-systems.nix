{ config, pkgs, ... }:

# File system mount points
{
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-partuuid/994a0edf-e344-4d21-80be-4db5736cc4c6";
      fsType = "vfat";
    };

    "/" = {
      device = "/dev/disk/by-partuuid/a18c445c-21fb-442a-ac0b-b2bb1fe9511a";
      fsType = "xfs";
    };

    # Hot data disk for cache, vm images, mirrors, etc
    "/data/1" = {
      device = "/dev/disk/by-partuuid/57f510ed-963a-4379-bb29-7b917e5e25dc";
      fsType = "xfs";
    };
  };

  swapDevices = [ ];
}
