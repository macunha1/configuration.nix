# modules/editors/vim.nix --- https://www.vim.org/
#
# For quick edits and writes, Vim suits better (due to its fast load time):
#   open, type, ESC, ESC, ESC, ZZ or :wq, done.

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.editors.vim = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.editors.vim.enable {
    my = {
      packages = with pkgs; [ editorconfig-core-c vim_configurable ];

      alias.v = "vim";

      env.VIMINIT = ''source "$XDG_CONFIG_HOME/vim/init.vim"'';

      home.xdg.configFile."vim" = {
        source = pkgs.fetchFromGitHub {
          owner = "macunha1";
          repo = "definitely-not-vimrc";

          rev = "4045927224d49837cdc8dc292740b5a06b18ed0f";
          sha256 = "1d01f95l1abl9rg38malkrmag798rcpsh50nw45dhvgdvn177fin";
        };

        recursive = true; # doesn't race against vim/plugins/dein.vim
      };

      home.xdg.configFile."vim/plugins/dein.vim" = {
        source = pkgs.fetchFromGitHub {
          owner = "Shougo";
          repo = "dein.vim";
          rev = "21a5c41f0289e98b8086279e62f046b2402dac7c";
          sha256 = "0kcln63kiivc0gyb82hc7ihgf9h2maj7y9ixn83z5sfk0yilmpxb";
        };

        recursive = true; # doesn't lock vim/plugins path
      };
    };
  };
}
