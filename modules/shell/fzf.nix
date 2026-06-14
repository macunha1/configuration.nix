# shell/fzf.nix -- https://github.com/junegunn/fzf
#
# Fuzzy Find ALL THE THINGS!
#
# Relative search for terminal. Hit Ctrl+R, type something close to what you
# think it is and VOI'LÁ!
#
# Linux: fzf fetched from GitHub and sourced manually in zsh/init.zsh.
# Darwin: programs.fzf managed declaratively by home-manager.

{
  config,
  options,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

with lib;

let
  # Color palette shared between Linux (FZF_DEFAULT_OPTS) and Darwin (programs.fzf.colors).
  fzfColors = {
    "fg" = "15"; # foreground: bright white
    "bg" = "0"; # background: black
    "hl" = "1"; # highlight matches: red
    "fg+" = "15"; # selected item foreground: bright white
    "hl+" = "14"; # selected item highlight: bright cyan
    "info" = "10"; # match count / info: bright green
    "prompt" = "12"; # prompt: bright blue
    "pointer" = "6"; # pointer to current item: cyan
    "marker" = "10"; # multi-select marker: bright green
    "spinner" = "14"; # loading spinner: bright cyan
    "header" = "14"; # header line: bright cyan
  };
in
{
  options.modules.shell.fzf = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.fzf.enable (mkMerge [

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = with pkgs; [
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
      env.FZF_DEFAULT_OPTS = escapeShellArgs (mapAttrsToList (k: v: "--color=${k}:${v}") fzfColors);

      # Autocompletion + key-bindings for ZSH
      modules.shell.zsh.init = mkIf config.modules.shell.zsh.enable ''
        source "$XDG_DATA_HOME/fzf/shell/completion.zsh"
        source "$XDG_DATA_HOME/fzf/shell/key-bindings.zsh"
      '';
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
        colors = fzfColors;
      };
    })
  ]);
}
