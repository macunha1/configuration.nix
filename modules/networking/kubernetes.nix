# modules/networking/kubernetes.nix --- https://kubernetes.io/
#
# Production-grade, de-facto Container Orchestration.
# Well ... Most probably, you already know Kubernetes.

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.networking.kubernetes = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    helm.enable = mkOption {
      type = types.bool;
      default = false;
    };

    kops.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkMerge [
    (mkIf config.modules.networking.kubernetes.enable {
      my.packages = with pkgs; [ minikube kubectl ];
    })

    (mkIf config.modules.networking.kubernetes.helm.enable {
      my.packages = with pkgs; [ helm ];
    })

    (mkIf config.modules.networking.kubernetes.kops.enable {
      my.packages = with pkgs; [ kops ];
    })
  ];
}
