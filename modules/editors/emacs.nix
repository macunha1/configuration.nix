# editors/emacs.nix -- https://www.gnu.org/software/emacs/
#
# Emacs + Doom configuration, with Evil activated, after all Vim <3
#
# Linux: regular GTK Emacs for the X11 session used by the desktop.
# Darwin: stock GNU Emacs from Nix, with native compilation enabled.
#
# Doom Emacs is NOT managed here -- clone it manually:
#   git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
#   ~/.config/emacs/bin/doom install

{
  config,
  lib,
  pkgs,
  inputs,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

with lib;

let
  inherit (lib.my or (import ../../lib/modules.nix { inherit lib; }))
    platformPath
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  # Doom module dependencies shared between Linux and Darwin.
  # Platform-specific packages (emacs binary, binutils, pinentry, fonts) are added per-section.
  sharedDeps = with pkgs; [
    (ripgrep.override { withPCRE2 = true; }) # :tools ripgrep (faster than silver-searcher)
    gnutls # TLS for Emacs-as-browser / package fetching
    zstd # undo-fu-session / undo-tree compression
    fd # fast file indexer (projectile / consult)

    # Doom module dependencies
    # :checkers spell
    (aspellWithDicts (
      ds: with ds; [
        en
        en-computers
        en-science
      ]
    ))
    # :tools lookup & :lang org +roam
    sqlite
    # :tools editorconfig
    editorconfig-core-c
  ];

  # Doom's :ui doom module uses nerd-icons; keep all-the-icons fonts for older
  # package consumers that still expect the legacy icon font families.
  emacsIconFontPackages = with pkgs; [
    nerd-fonts.symbols-only
    emacs-all-the-icons-fonts
  ];

  nerdSymbolsFontDir = "${pkgs.nerd-fonts.symbols-only}/share/fonts/truetype/NerdFonts/Symbols";
  allTheIconsFontDir = "${pkgs.emacs-all-the-icons-fonts}/share/fonts/all-the-icons";

  emacsDarwinIconFontFiles = [
    {
      name = "SymbolsNerdFontMono-Regular.ttf";
      source = "${nerdSymbolsFontDir}/SymbolsNerdFontMono-Regular.ttf";
    }
    {
      name = "SymbolsNerdFont-Regular.ttf";
      source = "${nerdSymbolsFontDir}/SymbolsNerdFont-Regular.ttf";
    }
    {
      name = "all-the-icons.ttf";
      source = "${allTheIconsFontDir}/all-the-icons.ttf";
    }
    {
      name = "file-icons.ttf";
      source = "${allTheIconsFontDir}/file-icons.ttf";
    }
    {
      name = "fontawesome.ttf";
      source = "${allTheIconsFontDir}/fontawesome.ttf";
    }
    {
      name = "material-design-icons.ttf";
      source = "${allTheIconsFontDir}/material-design-icons.ttf";
    }
    {
      name = "octicons.ttf";
      source = "${allTheIconsFontDir}/octicons.ttf";
    }
    {
      name = "weathericons.ttf";
      source = "${allTheIconsFontDir}/weathericons.ttf";
    }
  ];

  emacsDarwinIconFontLinks = builtins.listToAttrs (
    map (fontFile: {
      name = "Library/Fonts/${fontFile.name}";
      value.source = fontFile.source;
    }) emacsDarwinIconFontFiles
  );

  emacsAliases = {
    e = "emacs";
  };
in
{
  options.modules.editors.emacs = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.editors.emacs.enable (mkMerge [
    (platformPath {
      inherit config isDarwin;
      paths = [ (xdg.concrete.config "emacs/bin") ];
      darwinTarget = "zsh";
    })

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages =
        with pkgs;
        [
          binutils # native-comp needs 'as', provided by binutils

          # Emacs 29+ with Native Compilation and GTK/X11 support.
          ((emacsPackagesFor emacs).emacsWithPackages (epkgs: [ epkgs.vterm ]))

        ]
        ++ sharedDeps
        ++ [

          (mkIf (config.programs.gnupg.agent.enable) pinentry_emacs) # in-emacs gnupg prompts

          languagetool # :checkers grammar
        ];

      environment.shellAliases = emacsAliases;

      home-manager.users.${config.user.name}.home.file.".local/share/applications/emacs.desktop".text = ''
        [Desktop Entry]
        Name=Emacs
        GenericName=Doom Emacs
        Comment=Edit text with Doom Emacs
        MimeType=text/english;text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/c++
        Exec=/etc/profiles/per-user/${config.user.name}/bin/emacs --init-directory /home/${config.user.name}/.config/emacs %F
        TryExec=/etc/profiles/per-user/${config.user.name}/bin/emacs
        Icon=emacs
        Type=Application
        Terminal=false
        Categories=Development;TextEditor;
        StartupNotify=true
        StartupWMClass=Emacs
      '';

      fonts.packages = emacsIconFontPackages;
    })

    # Darwin (MacOS)
    # Use stock GNU Emacs from Nix instead of Homebrew/Emacs.app. Doom manages
    # Elisp packages; Nix provides Emacs plus runtime/tooling dependencies.
    (optionalAttrs isDarwin {
      home.packages =
        with pkgs;
        [
          (emacs.override { withNativeCompilation = true; })
          fontconfig # provides fc-list for Doom's icon font checks
        ]
        ++ sharedDeps
        ++ emacsIconFontPackages;

      home.file = emacsDarwinIconFontLinks;

      modules.shell.zsh.aliases = emacsAliases;
    })
  ]);
}
