{ config, options, pkgs, lib, ... }:
with lib; {
  options.modules.shell.fzf = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.fzf.enable {
    user.packages = with pkgs;
      [
        fzf # fuzzy-finder all the things
      ];

    home.dataFile."fzf" = {
      source = pkgs.fetchFromGitHub {
        owner = "junegunn";
        repo = "fzf";
        rev = "0.22.0";
        sha256 = "0n0cy5q2r3dm1a3ivlzrv9c5d11awxlqim5b9x8zc85dlr73n35l";
      };
    };

    env.FZF_HOME = "$XDG_DATA_HOME/fzf";
    env.FZF_DEFAULT_OPTS = escapeShellArgs [
      "--color=fg:15,bg:0,hl:1,spinner:14"
      "--color=fg+:15,hl+:14"
      "--color=header:14,info:10,pointer:6"
      "--color=marker:10,prompt:12"
    ];

    # Autocompletion for ZSH
    zsh.rc = mkIf config.modules.shell.zsh.enable ''
      source "$XDG_DATA_HOME/fzf/shell/completion.zsh"
      source "$XDG_DATA_HOME/fzf/shell/key-bindings.zsh"
    '';
  };
}
