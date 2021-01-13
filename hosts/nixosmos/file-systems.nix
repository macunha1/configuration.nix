{ config, pkgs, ... }:

# File system mount points
{
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-uuid/2AD3-7C9D";
      fsType = "vfat";
    };

    "/" = {
      device = "/dev/disk/by-uuid/68b0839d-c6b1-44bc-949c-4401fa380b95";
      fsType = "xfs";
    };

    # Home for users, allows sharing between OS and specific encryption
    "/home" = {
      device = "/dev/disk/by-uuid/6fe51f46-95c5-4e5f-87f3-a98446095473";
      fsType = "xfs";
    };

    # NVMe parition for /nix, allows sharing between OS
    "/nix" = {
      device = "/dev/disk/by-uuid/94f1d67f-75b3-4986-88cc-f88a1ea78985";
      fsType = "xfs";
    };

    # Cold data disk, mostly used for back-ups
    # "/data/0" = { };

    # Hot data disk for cache, vm images, mirrors, etc
    "/data/1" = {
      device = "/dev/disk/by-uuid/4d1c9a83-9c77-4254-a28a-244863f0f106";
      fsType = "xfs";
    };
  };

  swapDevices = [ ];
}
