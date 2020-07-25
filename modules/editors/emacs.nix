# Doom Emacs configuration, with Evil activated, after all Vim <3

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.editors.emacs = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.editors.emacs.enable {
    my = {
      packages = with pkgs; [
        emacsUnstable
        (ripgrep.override {withPCRE2 = true;})
        
        gnutls  # TLS connectivity
        zstd    # undo-fu-session/undo-tree compression
        fd      # speed-up projectile indexing

        ## Module dependencies
        # :checkers spell
        aspell
        aspellDicts.en
        aspellDicts.en-computers # English Computer Jargon dict
        aspellDicts.en-science   # English Scientic Jargon dict

        languagetool # :checkers grammar

        editorconfig-core-c # :tools editorconfig
        direnv              # :tools direnv -> extends lorri
      ];

      env.PATH = [ "$XDG_CONFIG_HOME/emacs/bin" ];
    };

    fonts.fonts = [
      pkgs.emacs-all-the-icons-fonts
    ];
  };
}
