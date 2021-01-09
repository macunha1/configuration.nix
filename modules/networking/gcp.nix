# modules/networking/gcp.nix -- https://cloud.google.com/
#
# Google Cloud Platform, next big thing in Cloud computing
# After all, everybody wants to be Google (look at Kubernetes raising
# popularity). Let's see how it goes

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.networking.gcp = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.networking.gcp.enable {
    user.packages = with pkgs; [ google-cloud-sdk ];

    env.BOTO_CONFIG = "$XDG_CONFIG_HOME/boto/config";
  };
}
