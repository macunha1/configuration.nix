# modules/networking/kubernetes.nix -- https://kubernetes.io/
#
# Production-grade, de-facto Container Orchestration.
# Well ... Most probably, you already know Kubernetes.

{ config, options, lib, pkgs, ... }:
with lib;
with lib.my; {
  options.modules.networking.kubernetes = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    minikube = {
      enable = mkOption {
        type = types.bool;
        default = config.modules.networking.kubernetes.enable;
      };

      home = mkOption {
        type = with types; (either str path);
        default = "$XDG_DATA_HOME/minikube";
      };
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

  config = mkIf config.modules.networking.kubernetes.enable (mkMerge [
    {
      user.packages = with pkgs;
        [
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
    }

    (mkIf config.modules.networking.kubernetes.minikube.enable {
      user.packages = with pkgs; [ minikube docker-machine-kvm2 ];

      env.MINIKUBE_HOME = config.modules.networking.kubernetes.minikube.home;
    })

    (mkIf config.modules.networking.kubernetes.helm.enable {
      user.packages = with pkgs; [ helm ];
    })

    (mkIf config.modules.networking.kubernetes.kops.enable {
      user.packages = with pkgs; [ kops ];
    })

    (mkIf config.modules.shell.zsh.ohMyZsh.enable {
      home.configFile."oh-my-zsh/custom/plugins/kubectl" = {
        source = "${configDir}/kubectl/zsh";
        recursive = true;
      };
    })
  ]);
}
