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

    antigen = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
    };

    ohMyZsh = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
    };
  };

  config = mkIf config.modules.shell.zsh.enable (mkMerge [
    {
      # Set ZSH as the default for users, even Apple is doing it now
      users.defaultUserShell = pkgs.zsh;

      programs.zsh = {
        enable = true;
        enableCompletion = true;

        histSize = config.modules.shell.zsh.historySize;
      };

      user.packages = with pkgs; [
        zsh

        ## Theme
        starship # Spaceship prompt reimplemented in Rust

        ## Utils
        htop # colorful top
        tldr # short man util
        tree # Tree view of dirs
        ripgrep # Fancy fast grep
        stow # GNU Stow, symlink manager
        jq # JSON for shell
        neofetch # Fancy fetch
      ];

      # ZSH
      env.ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
      env.ZSH_CACHE = "$XDG_CACHE_HOME/zsh";

      # Write variables down to ZSH files
      home.configFile = {
        "zsh" = {
          source = <config/zsh>;
          # Write it recursively to not overwrie other modules
          recursive = true;
        };

        "zsh/init.zsh".text = let
          aliasLines =
            mapAttrsToList (n: v: ''alias ${n}="${v}"'') config.my.alias;
        in ''
          # WARNING: Content autogenerated, edits can be overwritten!
          ${concatStringsSep "\n" aliasLines}
          ${config.zsh.rc}
        '';

        "zsh/env.zsh".text = ''
          # WARNING: Content autogenerated, edits can be overwritten!
          ${config.zsh.env}

          source $ZDOTDIR/.zprofile # TODO: CHANGE ME!
        '';
      };

      home.configFile."starship.toml" = {
        source = <config/starship/config.toml>;
      };
    }

    (mkIf config.modules.shell.zsh.antigen.enable {
      # Antigen
      env.ADOTDIR = "$XDG_CONFIG_HOME/antigen";
      # ANTIGEN_HOME is not an official env var, used for convenience in .zshrc
      env.ANTIGEN_HOME = "$XDG_CONFIG_HOME/zsh/custom/plugins/antigen";
      env.ANTIGEN_CACHE = "$XDG_CACHE_HOME/antigen";
      env.ANTIGEN_DEBUG_LOG = "/dev/null";

      home.configFile."zsh/custom/plugins/antigen" = {
        source = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "antigen";
          rev = "v2.2.3";
          sha256 = "1hqnwdskdmaiyi1p63gg66hbxi1igxib6ql8db3w950kjs1cs7rq";
        };
      };
    })

    (mkIf config.modules.shell.zsh.ohMyZsh.enable {
      # Oh-my-zsh
      env.ZSH = "$XDG_CONFIG_HOME/oh-my-zsh";
      env.ZSH_CUSTOM = "$XDG_CONFIG_HOME/oh-my-zsh/custom";
      env.DISABLE_AUTO_UPDATE = "true"; # as Nix makes the repo path read-only

      zsh.env = ''
        export ZSH="${config.my.env.ZSH}"
        export ZSH_CUSTOM="${config.my.env.ZSH_CUSTOM}"

        export DISABLE_UPDATE_PROMPT="true"
        export COMPLETION_WAITING_DOTS="true"
      '';

      home.configFile."oh-my-zsh" = {
        source = pkgs.fetchFromGitHub {
          owner = "ohmyzsh";
          repo = "ohmyzsh";
          rev = "93c837fec8e9fe61509b9dff9e909e84f7ebe32d";
          sha256 = "1ww50c1xf64z1m0sy30xaf2adr87cqr5yyv9jrqr227j97vrwj04";
        };

        recursive = true;
      };
    })
  ]);
}
