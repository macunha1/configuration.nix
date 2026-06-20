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
      python = {
        enable = true;
      };

      lua = {
        enable = true;
        jit.enable = true;
      };

      node = {
        enable = true;
        bun.enable = true;
      };

      go = {
        enable = true;
        languageServer.enable = true;
      };

      rust = {
        enable = true;
        languageServer.enable = true;
      };
    };

    networking = {
      kubernetes = {
        enable = true;
        helm.enable = true;
      };

      terraform.enable = true;
    };
  };
}
