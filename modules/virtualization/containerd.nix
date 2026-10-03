# virtualization/containerd.nix -- https://containerd.io/

{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
{
  options.modules.virtualization.containerd = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.virtualization.containerd.enable {
    user.packages = [ pkgs.nerdctl ];

    virtualisation.containerd.enable = true;
  };
}
