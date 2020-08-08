# modules/networking/gcp.nix --- https://cloud.google.com/
#
# Google Cloud Platform, next big thing in Cloud computing
# After all, everybody wants to be Google (look at Kubernetes).

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.networking.gcp = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.networking.gcp.enable {
    my.packages = with pkgs; [ google-cloud-sdk ];
  };
}