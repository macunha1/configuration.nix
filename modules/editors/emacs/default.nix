# editors/emacs/default.nix -- https://www.gnu.org/software/emacs/

{
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:

with lib;

let
  inherit (lib.my or (import ../../../lib/modules/utils.nix { inherit lib; }))
    mapModules
    ;

  sourceCodePro = import ../../../lib/fonts/source-code-pro.nix { inherit pkgs; };

  emacsAliases = {
    e = "emacs";
  };

  baseEmacsPackage =
    if isDarwin then
      pkgs.my.emacs-plus-darwin
    else
      (pkgs.emacsPackagesFor (
        pkgs.emacs.override {
          withMailutils = false;
          withNativeCompilation = config.modules.editors.emacs.nativeCompilation.enable;
        }
      )).emacsWithPackages
        (_: [ ]);

  emacsPackage =
    if config.modules.editors.emacs.runtimeEnvironment == { } then
      baseEmacsPackage
    else
      pkgs.symlinkJoin {
        name = "emacs-with-runtime-environment";
        paths = [ baseEmacsPackage ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          for emacsExecutable in emacs emacsclient; do
            if [ -e "$out/bin/$emacsExecutable" ]; then
              wrapProgram "$out/bin/$emacsExecutable" \
                ${concatMapStringsSep " \\\n                " (
                  name:
                  "--set ${escapeShellArg name} ${
                    escapeShellArg config.modules.editors.emacs.runtimeEnvironment.${name}
                  }"
                ) (attrNames config.modules.editors.emacs.runtimeEnvironment)}
            fi
          done
        '';
      };

in
{
  imports = attrValues (mapModules ./. import);

  options.modules.editors.emacs = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    nativeCompilation.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to build Linux Emacs with native compilation support.";
    };

    font = {
      family = mkOption {
        type = types.str;
        default = sourceCodePro.family;
        description = "Font family used by Emacs; Source Code Pro is installed automatically when selected.";
      };

      size = mkOption {
        type = types.ints.positive;
        default = 14;
        description = "Font size used by Emacs.";
      };
    };

    runtimeEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      internal = true;
      description = "Environment required by the configured Emacs runtime.";
    };

    package = mkOption {
      type = types.package;
      default = emacsPackage;
      readOnly = true;
      internal = true;
      description = "Emacs package with its module-owned runtime environment.";
    };
  };

  config = mkIf config.modules.editors.emacs.enable (mkMerge [
    (optionalAttrs (!isDarwin) {
      user.packages = [
        config.modules.editors.emacs.package
      ]
      ++ optionals config.modules.editors.emacs.nativeCompilation.enable [ pkgs.binutils ];

      fonts.packages = optionals (config.modules.editors.emacs.font.family == sourceCodePro.family) [
        sourceCodePro.package
      ];

      environment.shellAliases = emacsAliases;

      home-manager.users.${config.user.name}.home.file.".local/share/applications/emacs.desktop".text = ''
        [Desktop Entry]
        Name=Emacs Client
        Comment=Edit text with Emacs
        MimeType=${
          concatStringsSep ";" [
            "text/english"
            "text/plain"
            "text/x-makefile"
            "text/x-c++hdr"
            "text/x-c++src"
            "text/x-chdr"
            "text/x-csrc"
            "text/x-java"
            "text/x-moc"
            "text/x-pascal"
            "text/x-tcl"
            "text/x-tex"
            "application/x-shellscript"
            "text/x-c"
            "text/c++"
          ]
        };
        Exec=${config.modules.editors.emacs.package}/bin/emacs %F
        TryExec=${config.modules.editors.emacs.package}/bin/emacs
        Icon=emacs
        Type=Application
        Terminal=false
        Categories=Development;TextEditor;
        StartupNotify=true
        StartupWMClass=Emacs
      '';
    })

    (optionalAttrs isDarwin {
      home.packages = [
        config.modules.editors.emacs.package
      ]
      ++ optionals (config.modules.editors.emacs.font.family == sourceCodePro.family) [
        sourceCodePro.package
      ];
      home.file = optionalAttrs (
        config.modules.editors.emacs.font.family == sourceCodePro.family
      ) sourceCodePro.darwinHomeFiles;
      modules.shell.zsh.aliases = emacsAliases;
    })
  ]);
}
