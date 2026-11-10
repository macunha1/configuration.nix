_:

{
  modules = {
    agents = {
      code = {
        claude.enable = true;
        codex.enable = true;
      };

      mcp = {
        codegraphcontext.enable = true;
        mempalace.enable = true;
        serena.enable = true;
      };

      plugins.context-mode.enable = true;
    };

    editors = {
      default = "vim";
      vim.enable = true;
      emacs.enable = true;
    };

    desktop.fonts.enable = true;

    shell = {
      grep.enable = true;
      devenv.enable = true;
      git.enable = true;
      zsh.enable = true;
      direnv.enable = true;
      fzf.enable = true;
      gnupg.enable = true;
      pass.enable = true;
      tmux.enable = true;
    };

    development = {
      nix = {
        enable = true;
        languageServer.enable = true;
      };
      bash = {
        enable = true;
        languageServer.enable = true;
      };
      cc.enable = true;

      python = {
        enable = true;
        languageServer.enable = true;
      };

      node = {
        enable = true;
        bun.enable = true;
      };

      go = {
        enable = true;
        languageServer.enable = true;
        includeBinToPath = true;
      };

      rust = {
        enable = true;
        languageServer.enable = true;
      };

      lua.enable = true;
      elixir = {
        enable = true;
        languageServer.enable = true;
      };
    };

    networking = {
      ansible = {
        enable = true;
        languageServer.enable = true;
      };
      gcp.enable = true;

      kubernetes = {
        enable = true;
        helm.enable = true;
        languageServer.enable = true;
        helm.languageServer.enable = true;
      };

      terraform = {
        enable = true;
        languageServer.enable = true;
      };
    };
  };
}
