{ config, lib, pkgs, options, ... }:

{
  modules = {
    desktop = {
      awesomewm.enable = true;
      terminal.alacritty.enable = true;

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
      kubernetes = {
        enable = true;
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
      };
    };
  };

  time.timeZone = "Europe/Berlin";
  my.user.extraGroups = [ "networkmanager" ];
}
