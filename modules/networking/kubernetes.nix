# modules/networking/kubernetes.nix --- https://kubernetes.io/
#
# Production-grade, de-facto Container Orchestration.
# Well ... Most probably, you already know Kubernetes.

{ config, options, lib, pkgs, ... }:
with lib; {
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

  config = mkIf config.modules.networking.kubernetes.enable {
    my = mkMerge [
      { packages = with pkgs; [ minikube kubectl ]; }

      (mkIf config.modules.networking.kubernetes.helm.enable {
        packages = with pkgs; [ helm ];
      })

      (mkIf config.modules.networking.kubernetes.kops.enable {
        packages = with pkgs; [ kops ];
      })

      (mkIf config.modules.shell.zsh.ohMyZsh.enable {
        home.xdg.configFile."oh-my-zsh/custom/plugins/kubectl" = {
          source = <config/kubectl/zsh>;
          recursive = true;
        };
      })
    ];
  };
}
