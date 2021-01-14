{ config, lib, pkgs, options, ... }:

{
  modules = {
    hardware = {
      audio.enable = true;
      bluetooth.enable = true;
      video = {
        enable = true;
        nvidia.enable = true;
      };
    };

    desktop = {
      enable = true;
      awesomewm.enable = true;

      terminal = {
        default = "alacritty";
        alacritty.enable = true;
      };

      applications = {
        calibre.enable = true;
        uhkAgent.enable = true;
        redshift.enable = true;

        rofi = {
          enable = true;
          theme = "yin-yang";
        };
      };

      browsers = {
        default = "chromium";
        chromium.enable = true;
      };

      gaming = {
        lutris.enable = true;
        steam = {
          enable = true;
          hardware.enable = true;
        };
      };
    };

    editors = {
      default = "vim";
      emacs.enable = true;
      vim.enable = true;
    };

    development = {
      cc.enable = true;
      node.enable = true;
      python.enable = true;
      rust.enable = true;
      ruby.enable = true;

      java = {
        enable = true;
        gradle.enable = true;
      };

      go = {
        enable = true;
        path = "/data/1/opt/go";
      };

      android = {
        enable = true;
        path = "/data/1/opt/android";
        includeBinToPath = true;
      };

      flutter = {
        enable = true;
        path = "/data/1/opt/flutter";
      };
    };

    media = {
      spotify = {
        enable = true;
        daemon = {
          enable = true;

          settings = {
            global = {
              username = "22l46w473dznfqimcwcetx4sa";
              password_cmd = "pass show spotify/macunha";
            };
          };
        };
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
      git.user = {
        name = "macunha1";
        email = "matheuz.a@gmail.com";
      };

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
        nvidia.enable = true;

        storagePath = "/data/1/var/lib/docker";
      };
    };
  };
}
