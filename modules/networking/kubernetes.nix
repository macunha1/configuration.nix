# modules/networking/kubernetes.nix -- https://kubernetes.io/
#
# Production-grade, de-facto Container Orchestration.
# Well ... Most probably, you already know Kubernetes.
#
# Both platforms wrap kubectl to enforce XDG config path (upstream ignores XDG).
# Ref: https://github.com/kubernetes/kubernetes/issues/56402
#
# Linux: kubectl, QEMU/KVM support for minikube.
# Darwin: pkgs.kubectl, minikube without KVM (uses hyperkit/qemu).

{
  config,
  options,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

with lib;

let
  # Some standalone evaluations pass plain nixpkgs.lib, so lib.my may be absent.
  # Import the generator directly in that case.
  inherit (lib.my or (import ../../lib/generators.nix { inherit lib pkgs; }))
    generatedFileWarning
    shellExports
    ;

  inherit (lib.my or (import ../../lib/modules.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  # XDG-compliant Kubernetes paths - shared by Linux env and generated ZSH.
  kubeEnvVars = {
    KUBECONFIG = xdg.shell.config "kubectl/config";
    KUBECACHE = xdg.shell.cache "kubectl/cache";
  };

  kubernetesEnvVars =
    optionalAttrs config.modules.networking.kubernetes.minikube.enable {
      MINIKUBE_HOME = config.modules.networking.kubernetes.minikube.home;
    }
    // optionalAttrs config.modules.networking.kubernetes.helm.enable {
      HELM_PLUGIN_DIR = xdg.shell.data "helm";
    };

  kubernetesPackages =
    [ ]
    ++ optional config.modules.networking.kubernetes.helm.enable helm
    ++ optional config.modules.networking.kubernetes.kops.enable kops;

  kubectl = pkgs.writeScriptBin "kubectl" ''
    #!${pkgs.stdenv.shell}
    ${generatedFileWarning { file = ./kubernetes.nix; }}
    exec ${pkgs.kubectl}/bin/kubectl \
         --cache-dir "$KUBECACHE" "$@"
  '';

  helm = pkgs.my.helm or (pkgs.callPackage ../../packages/helm.nix { });

  kops = pkgs.kops.overrideAttrs (
    finalAttrs: previousAttrs: {
      version = "1.35.1";

      src = pkgs.fetchFromGitHub {
        owner = "kubernetes";
        repo = "kops";
        rev = "v${finalAttrs.version}";
        hash = "sha256-v2oudbdzbeEr4dlEgEs0+TqBqdmdhnlzwcrEt6BTLXk=";
      };

      ldflags = [
        "-s"
        "-w"
        "-X k8s.io/kops.Version=${finalAttrs.version}"
        "-X k8s.io/kops.GitVersion=${finalAttrs.version}"
      ];
    }
  );
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
        default = false;
      };

      home = mkOption {
        type = with types; (either str path);
        default = xdg.concrete.data "minikube";
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

    (mkIf (kubernetesPackages != [ ]) (platformPackages {
      inherit isDarwin;
      packages = kubernetesPackages;
    }))

    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = kubeEnvVars // kubernetesEnvVars;
      darwinTarget = "zsh";
    })

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) (mkMerge [
      {
        user.packages = [ kubectl ];
      }

      (mkIf config.modules.networking.kubernetes.minikube.enable {
        user.packages = with pkgs; [
          (minikube.override { withQemu = true; })
          qemu_kvm # QEMU/KVM-backed VM driver for minikube on Linux
        ];
      })
    ]))

    # Darwin (MacOS)
    (optionalAttrs isDarwin (mkMerge [
      {
        home.packages = [ kubectl ];
      }

      (mkIf config.modules.networking.kubernetes.minikube.enable {
        home.packages = with pkgs; [
          minikube # uses hyperkit or qemu on macOS; no KVM driver
        ];
      })
    ]))
  ]);
}
