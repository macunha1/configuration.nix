{ config, lib, pkgs, options, ... }:

{
  modules = {
    desktop = {
      enable = true;
      awesomewm.enable = true;

      terminal = {
        default = "alacritty";
        alacritty.enable = true;
      };

      applications = {
        redshift.enable = true;
        rofi.enable = true;
      };

      browsers = {
        default = "chromium";
        chromium.enable = true;
      };
    };

    editors = {
      default = "vim";
      emacs.enable = true;
      vim.enable = true;
    };

    # Get as much development modules ON as possible, protect these ones at all
    # cost! Search for issues and fix it, keep on dev'in!
    development = {
      cc.enable = true;
      elixir.enable = true;

      python = {
        enable = true;
        languageServer.enable = true;
      };

      lua = {
        enable = true;
        languageServer.enable = true;
      };

      rust = {
        enable = true;
        languageServer.enable = true;
      };

      go = {
        enable = true;
        languageServer.enable = true;
      };

      node = {
        enable = true;
        languageServer.enable = true;
      };
    };

    networking = {
      kubernetes = {
        enable = true;
        helm.enable = true;
        kops.enable = true;
      };

      vagrant = {
        enable = true;
        provider = "libvirt";
      };

      aws = {
        enable = true;
        iamAuthenticator.enable = true;
      };

      gcp.enable = true;
      terraform.enable = true;
    };

    shell = {
      git.user.name = "Matheus Cunha";

      zsh.enable = true;
      fzf.enable = true;
      tmux.enable = true;
      pass.enable = true;
      gnupg.enable = true;
      direnv.enable = true;
      asdf.enable = true;
    };

    virtualization = {
      kvm2.enable = true;

      docker = {
        enable = true;

        storagePath = "/var/lib/docker";
      };
    };
  };
}
