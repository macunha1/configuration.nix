# shell/asdf.nix -- https://github.com/asdf-vm/asdf
#
# "One version manager to rule them all,
#  One version manager to find them,
#  One version manager to install them all
#  and in the terminal bind them."
#
# Helps enormously when managing many fleets of servers where some tools are
# diverging such as Kops, Terraform and even JQ.

{
  config,
  options,
  pkgs,
  lib,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

with lib;

let
  asdfSrc = pkgs.fetchFromGitHub {
    owner = "asdf-vm";
    repo = "asdf";
    rev = "ac1a35b85bde049b9e2d531032eb55534e38ffe7";
    sha256 = "1mdj5alllbafy8r47fna5daib5idi99a72312xvacsd2597id28h";
  };
in
{
  options.modules.shell.asdf = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.asdf.enable (mkMerge [

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      home.dataFile."asdf".source = asdfSrc;
      env.ASDF_DATA_DIR = "$XDG_CACHE_HOME/asdf";
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      xdg.dataFile."asdf".source = asdfSrc;
      modules.shell.zsh.env = ''
        export ASDF_DATA_DIR="${config.xdg.cacheHome}/asdf"
      '';
    })

    # Both platforms: source asdf init when zsh is enabled.
    (mkIf config.modules.shell.zsh.enable {
      modules.shell.zsh.init = ''
        source "$XDG_DATA_HOME/asdf/asdf.sh"
        source "$XDG_DATA_HOME/asdf/completions/asdf.bash"
      '';
    })
  ]);
}
