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
    shellExports
    ;

  terraformEnvVars = {
    TF_CLI_CONFIG_FILE = "$XDG_CONFIG_HOME/terraform/rc.hcl";
  };

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
    rev = "765393233a42ea4d854059a40b6ef6961132fd78";
    hash = "sha256-00fLxHX0WadJ1RXBfp8CVc377kxFmB2bZZjmRHuOZLQ=";
  };

  # Implement a Terraform wrapper, with a pass-backed secret store for the API
  # tokens. Tokens are expected to be inside `tokens/terraform/<TF_URL>` e.g.:
  # `tokens/terraform/app.terraform.io` for HashiCorp Terraform Cloud.
  #
  # Which is implemented to [1] enhance security on the API token, and
  # [2] support XDG config dirs (i.e.: workaround enforced ~/.terraform.d/ for
  # the credentials), allowing to set TF_CLI_CONFIG_FILE and keep that
  # unambiguous.
  terraformWrapper = pkgs.writeScriptBin "terraform" ''
    #!${pkgs.stdenv.shell}
    ${generatedFileWarning { file = ./terraform.nix; }}
    set -e

    # Load pass-backed Terraform tokens into TF_TOKEN_* variables.
    load_terraform_tokens() {
      local token_root secret token_secret_path env_name token

      token_root="${config.xdg.configHome}/pass/tokens/terraform"
      [[ -n "''${PASSWORD_STORE_DIR:-}" ]] && \
        token_root="''${PASSWORD_STORE_DIR}/tokens/terraform"
      [[ -d "''${token_root}" ]] || return 0

      while IFS= read -r secret; do
        token_secret_path="''${secret#"$token_root"/}"
        token_secret_path="''${token_secret_path%.gpg}"

        env_name="$(printf '%s\n' "''${token_secret_path}" | \
          awk '{ gsub(/[.\/-]/, "_"); print "TF_TOKEN_" $0 }')"
        token="$(pass show "tokens/terraform/''${token_secret_path}")"
        export "''${env_name}=''${token}"
      done < <(find "''${token_root}" -type f -name '*.gpg' | sort)
    }

    terraform_subcommand() {
      local arg

      for arg in "$@"; do
        case "''${arg}" in
          -chdir=*)
            ;;
          -help|--help|-version|--version)
            return 1
            ;;
          -*)
            ;;
          *)
            printf '%s\n' "''${arg}"
            return 0
            ;;
        esac
      done

      return 1
    }

    terraform_is_help_or_version() {
      local arg

      for arg in "$@"; do
        case "''${arg}" in
          -help|--help|-version|--version)
            return 0
            ;;
        esac
      done

      return 1
    }

    terraform_command_loads_tokens() {
      local command

      [[ "''${TERRAFORM_WRAPPER_LOAD_TOKENS:-}" == "1" ]] && return 0
      [[ "''${TERRAFORM_WRAPPER_SKIP_TOKENS:-}" == "1" ]] && return 1
      terraform_is_help_or_version "$@" && return 1

      command="$(terraform_subcommand "$@")" || return 1

      case "''${command}" in
        apply|destroy|force-unlock|get|import|init|login|logout|output|plan|providers|refresh|state|taint|test|untaint|workspace)
          return 0
          ;;
      esac

      return 1
    }

    terraform_command_loads_tokens "$@" && load_terraform_tokens
    exec ${terraformBin}/bin/terraform "$@"
  '';

  # Implement a binary that re-uses upstream binary from HashiCorp instead of
  # compiling Terraform locally (nixpkgs default, as of this writing)
  terraformBin = pkgs.callPackage ../../packages/terraform-bin.nix { };

  terraformPackage =
    if config.modules.networking.terraform.wrapper.enable then terraformWrapper else terraformBin;
in
{
  options.modules.networking.terraform = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    # Whether or not to enable the Terraform Wrapper that supports the
    # pass-backed secret store for API tokens, this is a requirement to support
    # XDG config dirs (i.e. avoid ~/.terraform.d completely)
    wrapper.enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.networking.terraform.enable (mkMerge [

    # Source the zsh plugin on both platforms when zsh is active.
    # Sourced from the Nix store.
    (mkIf config.modules.shell.zsh.enable {
      modules.shell.zsh.init = ''
        source "${zshPlugin}/terraform.plugin.zsh"
      '';

      modules.shell.zsh.env = ''
        ${shellExports terraformEnvVars}
      '';
    })

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = [ terraformPackage ];

      home.configFile."terraform/rc.hcl".text = terraformRcText;
      env = terraformEnvVars;
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      home.packages = [ terraformPackage ];
      home.sessionVariables = terraformEnvVars;

      xdg.configFile."terraform/rc.hcl".text = terraformRcText;
    })
  ]);
}
