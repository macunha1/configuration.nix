# virtualization/kvm2.nix -- https://www.linux-kvm.org/page/Main_Page
#
# Full and native Linux virtualization using Libvirt to manage KVM (Kernel-based
# Virtual Machines) in Linux. KVM is the best open-source solution for
# virtualization out there.

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

    # NixOS installs kvm2 when libvirtd is enabled. Therefore this simple
    # configuration is all that is needed.
    virtualisation.libvirtd.enable = true;
  };
}
