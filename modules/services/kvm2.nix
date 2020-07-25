{ config, options, pkgs, lib, ... }:
with lib;
{
  options.modules.services.kvm2 = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.services.kvm2.enable {
    my.user.extraGroups = [ "libvirtd"  ];

    virtualisation.libvirtd.enable = true;
  };
}
