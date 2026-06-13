# modules/networking/kubernetes.nix -- https://kubernetes.io/
#
# Production-grade, de-facto Container Orchestration.
# Well ... Most probably, you already know Kubernetes.
#
# Both platforms wrap kubectl to enforce XDG config path (upstream ignores XDG).
# Ref: https://github.com/kubernetes/kubernetes/issues/56402
#
# Linux: pkgs.unstable.kubectl, docker-machine-kvm2 for minikube.
# Darwin: pkgs.kubectl, minikube without KVM (uses hyperkit/qemu).

{ config, options, lib, pkgs, isDarwin ? pkgs.stdenv.isDarwin, ... }:

with lib;

let
  # XDG-compliant Kubernetes paths - same values on both platforms.
  kubeEnvVars = {
    KUBECONFIG = "$XDG_CONFIG_HOME/kubectl/config";
    KUBECACHE  = "$XDG_CACHE_HOME/kubectl/cache";
  };
in
{
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

    # Both platforms: source kubectl plugin (aliases + cached completion) when zsh is enabled.
    # Plugin handles completion with caching - does not spawn kubectl on every shell start.
    (mkIf config.modules.shell.zsh.enable {
      modules.shell.zsh.init = ''
        source ${../../config/kubectl/zsh/kubectl.plugin.zsh}
      '';
    })

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) (mkMerge [
      {
        user.packages = with pkgs; [
          (writeScriptBin "kubectl" ''
            #!${stdenv.shell}
            exec ${unstable.kubectl}/bin/kubectl \
                 --cache-dir $KUBECACHE "$@"
          '')
        ];

        env = kubeEnvVars;
      }

      (mkIf config.modules.networking.kubernetes.minikube.enable {
        user.packages = with pkgs; [
          minikube
          docker-machine-kvm2 # KVM-backed VM driver for minikube on Linux
        ];

        env.MINIKUBE_HOME = config.modules.networking.kubernetes.minikube.home;
      })

      (mkIf config.modules.networking.kubernetes.helm.enable {
        user.packages = with pkgs; [ unstable.kubernetes-helm ];
        env.HELM_PLUGIN_DIR = "$XDG_DATA_HOME/helm";
      })

      (mkIf config.modules.networking.kubernetes.kops.enable {
        user.packages = with pkgs; [ kops ];
      })
    ]))

    # Darwin (MacOS)
    (optionalAttrs isDarwin (mkMerge [
      {
        home.packages = with pkgs; [
          (writeScriptBin "kubectl" ''
            #!${stdenv.shell}
            exec ${kubectl}/bin/kubectl \
                 --cache-dir $KUBECACHE "$@"
          '')
        ];

        modules.shell.zsh.env = ''
          export KUBECONFIG="${config.xdg.configHome}/kubectl/config"
          export KUBECACHE="${config.xdg.cacheHome}/kubectl/cache"
        '';
      }

      (mkIf config.modules.networking.kubernetes.minikube.enable {
        home.packages = with pkgs; [
          minikube # uses hyperkit or qemu on macOS; no KVM driver
        ];

        modules.shell.zsh.env = ''
          export MINIKUBE_HOME="${config.modules.networking.kubernetes.minikube.home}"
        '';
      })

      (mkIf config.modules.networking.kubernetes.helm.enable {
        home.packages = with pkgs; [ kubernetes-helm ];
        modules.shell.zsh.env = ''
          export HELM_PLUGIN_DIR="${config.xdg.dataHome}/helm"
        '';
      })

      (mkIf config.modules.networking.kubernetes.kops.enable {
        home.packages = with pkgs; [ kops ];
      })
    ]))
  ]);
}
