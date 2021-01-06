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
    user.packages = with pkgs; [ editorconfig-core-c vim_configurable ];

    environment.shellAliases = { v = "vim"; };

    env.VIMINIT = ''source "$XDG_CONFIG_HOME/vim/init.vim"'';

    home.configFile."vim" = {
      source = pkgs.fetchFromGitHub {
        owner = "macunha1";
        repo = "definitely-not-vimrc";

        rev = "2fae56a962aa2213609b6c27d4d775e1473f005c";
        sha256 = "0j15w7q2imlsqvgpmik8fg3f4l7z1gr565ijg941kcxb9bqv9ix7";
      };

      recursive = true; # doesn't race against vim/plugins/dein.vim
    };

    home.configFile."vim/plugins/dein.vim" = {
      source = pkgs.fetchFromGitHub {
        owner = "Shougo";
        repo = "dein.vim";
        rev = "21a5c41f0289e98b8086279e62f046b2402dac7c";
        sha256 = "0kcln63kiivc0gyb82hc7ihgf9h2maj7y9ixn83z5sfk0yilmpxb";
      };

      recursive = true; # doesn't lock vim/plugins path
    };
  };
}
