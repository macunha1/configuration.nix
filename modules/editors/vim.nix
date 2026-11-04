# editors/vim.nix -- https://www.vim.org/
#
# For quick edits and writes, Vim suits better (due to its fast load time):
#   open, type, ESC, ESC, ESC, ZZ or :wq, done.

{
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:
with lib;

let
  inherit (lib.my or (import ../../lib/generators.nix { inherit lib pkgs; }))
    shellExports
    ;

  inherit (lib.my or (import ../../lib/modules/utils.nix { inherit lib; }))
    platformEnv
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  # Fetched once; referenced in both Linux (home.configFile) and Darwin (xdg.configFile).
  vimrcSrc = pkgs.fetchFromGitHub {
    owner = "macunha1";
    repo = "definitely-not-vimrc";
    rev = "c0f6d1d06c63fa07f1eaf8bdb35905b5be2640cb";
    sha256 = "0nbrq5va8y92wqddlyk26av56y2nam43lanzrcppf4b85f4069g6";
  };

  # Bootstrap vim-plug separately from the read-only configuration source.
  vimPlugSrc = pkgs.fetchFromGitHub {
    owner = "junegunn";
    repo = "vim-plug";
    rev = "7e5aae5e1187842cb0b1d8def986e48d481c4410";
    sha256 = "1hb20bpbif44vl6savp69gwrcc94zhf7c662pzwkzmk5br5hqq3g";
  };

  vimAliases = {
    v = "vim";
  };

  vimEnvVars = {
    VIMINIT = "source ${xdg.concrete.config "vim/init.vim"}";
  };
in
{
  options.modules.editors.vim = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.editors.vim.enable (mkMerge [
    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = vimEnvVars;
      target = "both";
    })

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = with pkgs; [
        editorconfig-core-c # honours .editorconfig in repos
        vim-full # full-featured vim with Python support
      ];

      environment.shellAliases = vimAliases;

      home.configFile."vim" = {
        source = vimrcSrc;
        recursive = true;
      };
      home.configFile."vim/autoload/plug.vim" = {
        source = "${vimPlugSrc}/plug.vim";
      };
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      home.packages = with pkgs; [
        editorconfig-core-c # honours .editorconfig in repos
        vim # vim on Darwin (vim_configurable -> vim in recent nixpkgs)
      ];

      modules.shell.zsh.aliases = vimAliases;

      xdg.configFile."vim" = {
        source = vimrcSrc;
        recursive = true;
      };

      xdg.configFile."vim/autoload/plug.vim" = {
        source = "${vimPlugSrc}/plug.vim";
      };
    })
  ]);
}
