# modules/shell/zsh.nix --- https://www.zsh.org
#
# ZSH, Oh my dear and loved ZSH.

{ config, options, pkgs, lib, ... }:
with lib; {
  options.modules.shell.zsh = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    historySize = mkOption {
      type = types.int;
      default = 9223372036854775807; # LONG_MAX: Unlimited
    };
  };

  config = mkIf config.modules.shell.zsh.enable {
    my = {
      packages = with pkgs; [
        zsh
        nix-zsh-completions

        ## Theme
        starship # Spaceship prompt reimplemented in Rust

        ## Utils
        fzf      # fuzzy-finder all the things
        htop     # colorful top
        tldr     # short man util
        tree     # Tree view of dirs
        ripgrep  # Fancy fast grep
        stow     # GNU Stow, symlink manager
        jq       # JSON for shell
        neofetch # Fancy fetch
      ];

      # TODO: Change from dotfiles to NixOS (fetch from Git)
      # home.xdg.configFile."zsh" = {
      #   source = <config/zsh>;
      #   # Write it recursively so other modules can write files to it
      #   recursive = true;
      # };

      zsh.rc = ''
        source $HOME/.zprofile
        source $HOME/.zshrc
      '';

      # Home Manager configuration
      home.programs.zsh.plugins = [{
        # Antigen to the rescue
        name = "antigen";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "antigen";
        };
      }];
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;

      histSize = config.modules.shell.zsh.historySize;
    };
  };
}
