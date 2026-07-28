# modules/networking/gcp.nix -- https://cloud.google.com/
#
# Google Cloud Platform, next big thing in Cloud computing.
# After all, everybody wants to be Google (look at Kubernetes raising
# popularity). Let's see how it goes.
#
# Linux: user.packages + env = gcpEnvVars.
# Darwin: home.packages + home.sessionVariables = gcpEnvVars.

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
  inherit (lib.my or (import ../../lib/generators.nix { inherit lib pkgs; }))
    shellExports
    ;

  inherit (lib.my or (import ../../lib/modules.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  pinnedGoogleCloudSdkVersion = "570.0.0";
  pinnedGkeGcloudAuthPluginVersion = "0.5.15";

  googleCloudSdk = pkgs.google-cloud-sdk;
  gkeGcloudAuthPlugin = googleCloudSdk.components.gke-gcloud-auth-plugin;

  pinnedGoogleCloudSdk = googleCloudSdk.withExtraComponents (
    optional config.modules.networking.kubernetes.enable gkeGcloudAuthPlugin
  );

  gcpPackages = [
    pinnedGoogleCloudSdk # gcloud, gsutil, bq, plus GKE auth plugin when Kubernetes is enabled
  ];

  # XDG-compliant GCP paths — same values on both platforms.
  gcpEnvVars = {
    BOTO_CONFIG = xdg.shell.config "boto/config"; # gsutil / Python boto config
    CLOUDSDK_CONFIG = xdg.shell.config "gcloud";

    # Cloud SDK is managed by Nix. Keep gcloud from recommending mutable
    # component-manager updates such as `gcloud components update`.
    CLOUDSDK_COMPONENT_MANAGER_DISABLE_UPDATE_CHECK = "true";
    CLOUDSDK_COMPONENT_MANAGER_FIXED_SDK_VERSION = pinnedGoogleCloudSdkVersion;
  };
in
{
  options.modules.networking.gcp = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.networking.gcp.enable (mkMerge [
    {
      assertions = [
        {
          assertion = googleCloudSdk.version == pinnedGoogleCloudSdkVersion;
          message = "google-cloud-sdk changed; update the pinned GCP SDK version intentionally.";
        }
      ]
      ++ optional config.modules.networking.kubernetes.enable {
        assertion = gkeGcloudAuthPlugin.version == pinnedGkeGcloudAuthPluginVersion;
        message = "gke-gcloud-auth-plugin changed; update the pinned GKE auth plugin version intentionally.";
      };
    }

    (platformPackages {
      inherit isDarwin;
      packages = gcpPackages;
    })

    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = gcpEnvVars;
      darwinTarget = "both";
    })
  ]);
}
