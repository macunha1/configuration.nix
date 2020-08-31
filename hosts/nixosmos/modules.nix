{ config, lib, pkgs, options, ... }:

{
  modules = {
    desktop = {
      awesomewm.enable = true;

      terminal = {
        default = "alacritty";
        alacritty.enable = true;
      };

      applications = {
        calibre.enable = true;
        uhkAgent.enable = true;
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

    development = {
      cc.enable = true;
      java.enable = true;
      node.enable = true;
      python.enable = true;
      rust.enable = true;

      go = {
        enable = true;
        path = "/data/1/opt/go";
      };
    };

    media = {
      spotify = {
        enable = true;
        daemon.enable = true;
      };

      mpv.enable = true;
    };

    networking = {
      kubernetes = {
        enable = true;

        minikube = {
          enable = true;
          home = "/data/1/opt/minikube";
        };

        helm.enable = true;
        kops.enable = true;
      };

      vagrant = {
        enable = true;
        home = "/data/1/opt/vagrant";
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
      zsh.enable = true;
      fzf.enable = true;
      tmux.enable = true;
      pass.enable = true;
      gnupg.enable = true;
      direnv.enable = true;
    };

    services = {
      kvm2.enable = true;

      docker = {
        enable = true;
        nvidia.enable = true;

        storagePath = "/data/1/var/lib/docker";
      };
    };
  };
}
