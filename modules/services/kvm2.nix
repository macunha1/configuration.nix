{ config, options, pkgs, lib, ... }:
with lib;
{
  options.modules.services.kvm = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.services.kvm.enable {
    my.user.extraGroups = [ "libvirtd"  ];
    boot.kernelModules  = [ "kvm-intel" ];

    virtualisation.libvirtd.enable = true;
  };
}
