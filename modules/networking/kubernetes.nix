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
      {
        packages = with pkgs; [
          minikube

          (writeScriptBin "kubectl" ''
            #!${stdenv.shell}
            exec ${unstable.kubectl}/bin/kubectl \
                 --cache-dir $KUBECACHE "$@"
          '')
        ];

        # Let's handle XDG dir specification on our own since Kubernetes'
        # devs aren't interested.
        # Ref: https://github.com/kubernetes/kubernetes/issues/56402
        env.KUBECONFIG = "$XDG_CONFIG_HOME/kubectl/config";
        env.KUBECACHE = "$XDG_CACHE_HOME/kubectl/cache";

        env.MINIKUBE_HOME = "$XDG_DATA_HOME/minikube";
      }

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
