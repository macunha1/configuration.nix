{ config, lib, pkgs, options, ... }:

{
  modules = {
    hardware = {
      audio.enable = true;
      bluetooth.enable = true;
      video = {
        enable = true;
        support32Bit.enable = true;
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
        redshift.enable = true;
        zsa.enable = true;

        rofi = {
          enable = true;
          theme = "yin-yang";
        };
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
      elixir.enable = true;
      java.enable = true;

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
        path = "/data/1/opt/go";
      };

      node = {
        enable = true;
        languageServer.enable = true;
      };

      android = {
        enable = false;
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

        minikube.enable = false;
        helm.enable = true;
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

      ansible.enable = true;
      terraform.enable = true;
    };

    shell = {
      git.user = {
        name = "Matheus Cunha";
        email = "stdin@macunha.me";
        gpgSigningKeyId = "D2E3640881D72B1C90BAD6E4F59CEBBC43F67CE2";
      };

      zsh.enable = true;
      fzf.enable = true;
      tmux.enable = true;
      pass.enable = true;
      gnupg.enable = true;
      direnv.enable = true;
      lorri.enable = true;
      asdf.enable = true;
    };

    virtualization = {
      kvm2.enable = true;
      oci.enable = true;
    };
  };
}
