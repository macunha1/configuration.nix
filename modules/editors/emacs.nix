# editors/emacs.nix -- https://www.gnu.org/software/emacs/
#
# Emacs + Doom configuration, with Evil activated, after all Vim <3

{ config, lib, pkgs, inputs, ... }:

with lib; {
  options.modules.editors.emacs = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.editors.emacs.enable {
    nixpkgs.overlays = [ inputs.emacs-overlay.overlay ];

    user.packages = with pkgs; [
      # Emacs native compilation dependencies
      binutils # native-comp needs 'as', provided by this

      # Emacs 29 with Native Compilation and Pure GTK3 (pgtk)
      ((emacsPackagesFor emacsPgtkNativeComp).emacsWithPackages
        (epkgs: [ epkgs.vterm ]))

      (ripgrep.override { withPCRE2 = true; })

      (mkIf (config.programs.gnupg.agent.enable)
        pinentry_emacs) # in-emacs gnupg prompts

      gnutls # TLS connectivity (Emacs as a browser accessing HTTPS pages)
      zstd # undo-fu-session/undo-tree compression
      fd # speed-up projectile indexing

      ## Doom Emacs module dependencies
      # :checkers spell
      (aspellWithDicts (ds: with ds; [ en en-computers en-science ]))

      languagetool # :checkers grammar
      editorconfig-core-c # :tools editorconfig
      sqlite # :tools lookup & :lang org +roam

      editorconfig-core-c # :tools editorconfig
    ];

    env.PATH = [ "$XDG_CONFIG_HOME/emacs/bin" ];

    environment.shellAliases = { e = "emacs"; };

    fonts.fonts = [ pkgs.emacs-all-the-icons-fonts ];
  };
}
