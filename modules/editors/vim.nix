# For quick stuff, Vim suits better, open, type, :wq, done.
# Usually this is configured as EDITOR and used also for git commits.

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.editors.vim = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.editors.vim.enable {
    my = {
      packages = with pkgs; [
        editorconfig-core-c
        vim_configurable
      ];

      # TODO: Adjust vim configurations to XDG, + fetch from Git
      # env.VIMINIT = "let \\$MYVIMRC='\\$XDG_CONFIG_HOME/vim/init.vim' | source \\$MYVIMRC";
      alias.v = "vim";
    };
  };
}
