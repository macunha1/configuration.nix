# shell/fzf.nix -- https://github.com/junegunn/fzf
#
# Fuzzy Find ALL THE THINGS!
#
# Relative search for terminal. Hit Ctrl+R, type something close to what you
# think it is and VOI'LÁ!
#
{
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:

with lib;

let
  inherit (lib.my or (import ../../lib/generators.nix { inherit lib pkgs; })) shellExports;

  inherit (lib.my or (import ../../lib/modules/utils.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

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

  fzfEnvVars = {
    FZF_DEFAULT_OPTS = escapeShellArgs (
      mapAttrsToList (name: value: "--color=${name}:${value}") fzfColors
    );
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
    (platformPackages {
      inherit isDarwin;
      packages = [ pkgs.fzf ];
    })

    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = fzfEnvVars;
      target = "both";
    })

    (mkIf config.modules.shell.zsh.enable {
      modules.shell.zsh.init = ''
        source "${pkgs.fzf}/share/fzf/completion.zsh"
        source "${pkgs.fzf}/share/fzf/key-bindings.zsh"
      '';
    })
  ]);
}
