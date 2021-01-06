{ config, ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/99bd3c8b-8eae-497f-ab4d-7a120db4c08c";
    fsType = "ext4";
  };

  swapDevices = [ ];
}
