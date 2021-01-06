# Doom Emacs configuration, with Evil activated, after all Vim <3

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.editors.emacs = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.editors.emacs.enable {
    user.packages = with pkgs; [
      emacsUnstable
      (ripgrep.override { withPCRE2 = true; })

      gnutls # TLS connectivity
      zstd # undo-fu-session/undo-tree compression
      fd # speed-up projectile indexing

      ## Module dependencies
      # :checkers spell
      (aspellWithDicts (ds: with ds; [ en en-computers en-science ]))

      languagetool # :checkers grammar
      editorconfig-core-c # :tools editorconfig
      sqlite # :tools lookup & :lang org +roam

      # TODO: Pending programming languages with conditional below
      # ccls # :lang cc
      # nodePackages.javascript-typescript-langserver # :lang javascript
      # :lang latex & :lang org (latex previews)
      # texlive.combined.scheme-medium
      # :lang rust
      # rustfmt
      # unstable.rust-analyzer

      editorconfig-core-c # :tools editorconfig
      direnv # :tools direnv -> extends lorri
    ];

    env.PATH = [ "$XDG_CONFIG_HOME/emacs/bin" ];

    environment.shellAliases = { e = "emacs"; };

    fonts.fonts = [ pkgs.emacs-all-the-icons-fonts ];
  };
}
