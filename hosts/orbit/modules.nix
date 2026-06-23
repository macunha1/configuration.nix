{ config, lib, pkgs, options, ... }:

{
  modules = {
    hardware = {
      audio.enable = true;
      bluetooth.enable = true;
      video.enable = true;
    };

    desktop = {
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

    development = {
      cc.enable = true;
      python.enable = true;
      rust.enable = true;
      go.enable = true;
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
    };

    networking = {
      kubernetes = {
        enable = true;

        helm.enable = true;
      };

      terraform.enable = true;
    };

    shell = {
      git.enable = true;
      zsh.enable = true;
      asdf.enable = true;
      direnv.enable = true;
      fzf.enable = true;
      gnupg.enable = true;
      pass.enable = true;
      tmux.enable = true;
    };
  };
}
