{ ... }:

{
  modules = {
    editors = {
      default = "vim";
      vim.enable = true;
      emacs.enable = true;
    };

    shell = {
      git.enable = true;
      zsh.enable = true;
      direnv.enable = true;
      fzf.enable = true;
      gnupg.enable = true;
      pass.enable = true;
      tmux.enable = true;
    };

    development = {
      node = {
        enable = true;
        bun.enable = true;
      };

      rust = {
        enable = true;
        languageServer.enable = true;
      };
    };

    networking.terraform.enable = true;
  };
}
