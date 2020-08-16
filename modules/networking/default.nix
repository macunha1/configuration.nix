# modules/networking --- Servers, Cloud and clusters management
#
# DEA: Data Engineering and Analytics
# ICE: Infrastructure and Cloud Engineering

{ pkgs, ... }: {
  imports = [
    # Config and Infra as Code
    ./terraform.nix

    # Virtualization
    ./kubernetes.nix
    ./vagrant.nix

    # Cloud computing
    ./aws.nix
    ./gcp.nix
  ];
}
