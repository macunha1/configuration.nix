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
          rev = "cd2c9881aa497bdc7dc3549186a2b8013db84abf";
          sha256 = "1zan3f8ksj86nrkdjjd14r4dx3hakl3j82f17fs2rg3nx03k02mb";
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
