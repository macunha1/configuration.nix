# networking/terraform.nix -- https://www.terraform.io/
#
# From the Chaos that is a Cloud Systems' Engineering life, Terraform is the
# only constant across configurations and providers.
#
# No matter if you're running a Data Lake, Serverless Web app or embedded
# system. On top of that at this point in time it doesn't even matter if you're
# using cloud, as you might as well order a Domino's pizza using Terraform.
# Ref: https://github.com/ndmckinley/terraform-provider-dominos
#
# NOTE: This module won't install Terraform due to the highly inconsistent
# amount of versions available (and in use) on the market. Instead, version
# managers with support for Terraform are encouraged, either "tfenv" or
# "asdf" with direnv integrated.

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
    ;

  # Terraform rc.hcl - same content on both platforms.
  # Disables telemetry and sets a shared plugin cache to avoid re-downloading.
  terraformRcText = ''
    ${generatedFileWarning { file = ./terraform.nix; }}
    plugin_cache_dir = "$XDG_CACHE_HOME/terraform/plugins"

    disable_checkpoint           = true
    disable_checkpoint_signature = true
  '';

  # ZSH plugin - fetched by Nix so it is pinned and reproducible.
  # The plugin extends OMZ's terraform support but has no OMZ dependency,
  # so it survives the planned OMZ removal.
  zshPlugin = pkgs.fetchFromGitHub {
    owner = "macunha1";
    repo = "zsh-terraform";
    rev = "fd1471d3757f8ed13f56c4426f88616111de2a87";
    sha256 = "02pw5xg72axdz7vcx0bk6hxi5a19xdpcqfg8vwzhd3nqyyvdfygk";
  };
in
{
  options.modules.networking.terraform = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.networking.terraform.enable (mkMerge [

    # Source the zsh plugin on both platforms when zsh is active.
    # Sourced from the Nix store.
    (mkIf config.modules.shell.zsh.enable {
      modules.shell.zsh.init = ''
        source "${zshPlugin}/terraform.plugin.zsh"
      '';
    })

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      home.configFile."terraform/rc.hcl".text = terraformRcText;
      env.TF_CLI_CONFIG_FILE = "$XDG_CONFIG_HOME/terraform/rc.hcl";
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      xdg.configFile."terraform/rc.hcl".text = terraformRcText;
      modules.shell.zsh.env = ''
        export TF_CLI_CONFIG_FILE="${config.xdg.configHome}/terraform/rc.hcl"
      '';
    })
  ]);
}
