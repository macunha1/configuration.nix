# For quick stuff, Vim suits better, open, type, :wq, done.
# Usually this is configured as EDITOR and used also for git commits.

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
          rev = "39aee6df68b6870efcfc12db92744ee0414fe3d0";
          sha256 = "0392jn933xrja5vzraf20rpjv0vkpgghh3589j1jlh8lkvkmjcp6";
        };

        recursive = true; # doesn't race against vim/bundle/vundle
      };

      home.xdg.configFile."vim/bundle/vundle" = {
        source = pkgs.fetchFromGitHub {
          owner = "VundleVim";
          repo = "Vundle.vim";
          rev = "v0.10.2";
          sha256 = "1nqb8iss7s9p0d65xlmd5wgf5qzwr6przq36605ff1knypazz86v";
        };

        recursive = true; # doesn't lock vim/bundle, plugins path
      };
    };
  };
}
