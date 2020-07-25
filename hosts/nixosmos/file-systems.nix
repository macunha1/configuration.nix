{ config, pkgs, ... }:

# File system mount points
{
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-uuid/E751-DAB7";
      fsType = "vfat";
    };

    "/" = {
      device = "/dev/disk/by-uuid/755daa8c-58c5-4569-823c-be0b284eb26d";
      fsType = "ext4";
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
    "/data/0" = {
      device = "/dev/disk/by-uuid/29b921c1-b46a-44ff-b8da-212b813dad1d";
      fsType = "ext4";
    };

    # Hot data disk for cache, vm images, mirrors, etc
    "/data/1" = {
      device = "/dev/disk/by-uuid/4d1c9a83-9c77-4254-a28a-244863f0f106";
      fsType = "xfs";
    };
  };

  swapDevices = [ ];
}
