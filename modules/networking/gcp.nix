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
  gcpPackages = with pkgs; [
    google-cloud-sdk # gcloud, gsutil, bq
  ];

  # XDG-compliant GCP paths — same values on both platforms.
  gcpEnvVars = {
    BOTO_CONFIG = "$XDG_CONFIG_HOME/boto/config"; # gsutil / Python boto config
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

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = gcpPackages;
      env = gcpEnvVars;
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      home.packages = gcpPackages;
      home.sessionVariables = gcpEnvVars;
    })
  ]);
}
