# virtualization/oci.nix -- https://opencontainers.org/
#
# Open Container Initiative was established by Docker Inc. The Docker v2 Engine
# was donated to the Linux Foundation under the OCI spec.
# Read this module as "Docker v2". The "works on my machine" killer

{ config, options, pkgs, lib, ... }:
with lib; {
  options.modules.virtualization.oci = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    storagePath = mkOption {
      type = with types; (either str path);
      default = "/var/lib/containers";
    };
  };

  config = mkIf config.modules.virtualization.oci.enable {
    user = {
      packages = with pkgs; [ buildah crun ];
      extraGroups = [ "containers" ];
    };
  };
}
