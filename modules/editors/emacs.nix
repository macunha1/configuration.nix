# editors/emacs.nix -- https://www.gnu.org/software/emacs/
#
# Emacs + Doom configuration, with Evil activated, after all Vim <3
#
# Linux: emacs-pgtk (pure GTK3, Wayland-native).
# Darwin: emacs-macport (railwaycat Cocoa port) -- provided by emacs-overlay.
#
# Doom Emacs is NOT managed here -- clone it manually:
#   git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
#   ~/.config/emacs/bin/doom install

{ config, lib, pkgs, inputs, isDarwin ? pkgs.stdenv.isDarwin, ... }:

with lib;

let
  # Doom module dependencies shared between Linux and Darwin.
  # Platform-specific packages (emacs binary, binutils, pinentry, fonts) are added per-section.
  sharedDeps = with pkgs; [
    (ripgrep.override { withPCRE2 = true; }) # :tools ripgrep (faster than silver-searcher)
    gnutls                                    # TLS for Emacs-as-browser / package fetching
    zstd                                      # undo-fu-session / undo-tree compression
    fd                                        # fast file indexer (projectile / consult)

    # Doom module dependencies
    # :checkers spell
    (aspellWithDicts (ds: with ds; [ en en-computers en-science ]))
    # :tools lookup & :lang org +roam
    sqlite
    # :tools editorconfig
    editorconfig-core-c
  ];

  emacsAliases = { e = "emacs"; };
in
{
  options.modules.editors.emacs = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.editors.emacs.enable (mkMerge [

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = with pkgs; [
        binutils # native-comp needs 'as', provided by binutils

        # Emacs 29+ with Native Compilation and Pure GTK3 (pgtk) for Wayland
        ((emacsPackagesFor emacs-pgtk).emacsWithPackages (epkgs: [ epkgs.vterm ]))

      ] ++ sharedDeps ++ [

        (mkIf (config.programs.gnupg.agent.enable)
          pinentry_emacs) # in-emacs gnupg prompts

        languagetool # :checkers grammar
      ];

      env.PATH = [ "$XDG_CONFIG_HOME/emacs/bin" ]; # doom sync, doom upgrade, etc.

      environment.shellAliases = emacsAliases;

      fonts.fonts = [ pkgs.emacs-all-the-icons-fonts ]; # used by doom's :ui icons
    })

    # Darwin (MacOS)
    # emacs-overlay is already applied to darwin pkgs in flake.nix
    (optionalAttrs isDarwin {
      home.packages = with pkgs; [
        # macOS-native Emacs; emacs-pgtk is Linux/GTK-only
        ((emacsPackagesFor emacs-macport).emacsWithPackages (epkgs: [ epkgs.vterm ]))

      ] ++ sharedDeps;

      modules.shell.zsh.env = ''
        export PATH="${config.xdg.configHome}/emacs/bin:$PATH"
      '';

      modules.shell.zsh.aliases = emacsAliases;
    })
  ]);
}
