{ config, lib, pkgs, options, ... }:

{
  modules = {
    desktop = {
      awesomewm.enable = true;
      terminal.alacritty.enable = true;

      applications = {
        uhkAgent.enable = true;
        redshift.enable = true;
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
      lua.enable = true;
      java.enable = true;
      rust.enable = true;
    };

    media = {
      spotify.enable = true;
      mpv.enable = true;
    };

    networking = {
      terraform.enable = true;

      kubernetes = {
        enable = true;
        helm.enable = true;
        kops.enable = true;
      };

      aws = {
        enable = true;
        iamAuthenticator.enable = true;
      };

      gcp = {
        enable = true;
      };
    };

    shell = {
      zsh.enable = true;
      tmux.enable = true;
      pass.enable = true;
      gnupg.enable = true;
      direnv.enable = true;
    };

    services = {
      calibre.enable = true;
      kvm2.enable = true;

      docker = {
        enable = true;
        nvidia.enable = true;
      };
    };
  };

  time.timeZone = "Europe/Berlin";
  my.user.extraGroups = [ "networkmanager" ];
}
