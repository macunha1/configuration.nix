{ config, options, pkgs, lib, ... }:
with lib; {
  options.modules.virtualization.kvm2 = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.virtualization.kvm2.enable {
    user.extraGroups = [ "libvirtd" ];

    virtualisation.libvirtd.enable = true;
  };
}
