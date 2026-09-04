# editors/emacs/doom.nix -- https://github.com/doomemacs/doomemacs
#
# Emacs + Doom configuration, with Evil activated, after all Vim <3.

{
  config,
  inputs,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:

with lib;

let
  inherit (lib.my or (import ../../../lib/generators.nix { inherit lib pkgs; }))
    generatedFileWarning
    shellExports
    ;

  inherit (lib.my or (import ../../../lib/modules/utils.nix { inherit lib; }))
    platformEnv
    platformPath
    ;

  xdg = (lib.my or (import ../../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  homeManagerLib = inputs.home-manager.lib.hm;

  homeManagerConfig = if isDarwin then config else config.home-manager.users.${config.user.name};

  doomEnvironment = {
    DOOMDIR = "${homeManagerConfig.xdg.configHome}/doom";
    DOOMLOCALDIR = "${homeManagerConfig.xdg.dataHome}/doom/local";
    DOOMPROFILELOADFILE = "${homeManagerConfig.xdg.dataHome}/doom/profiles.el";
    EMACSDIR = "${homeManagerConfig.xdg.configHome}/emacs";
    XDG_CACHE_HOME = homeManagerConfig.xdg.cacheHome;
    XDG_CONFIG_HOME = homeManagerConfig.xdg.configHome;
    XDG_DATA_HOME = homeManagerConfig.xdg.dataHome;
    XDG_STATE_HOME = homeManagerConfig.xdg.stateHome;
  };

  doomPrivateOptions = {
    identity = {
      fullName = mkOption {
        type = types.str;
        default = "Example User";
        description = "Full name rendered as Doom's user-full-name.";
      };

      email = mkOption {
        type = types.str;
        default = "example@macunha.com";
        description = "Email address rendered as Doom's user-mail-address.";
      };
    };

    org.cryptKey = mkOption {
      type = types.str;
      default = "1ABC234EXAMPLE5678";
      description = "OpenPGP key ID used by Org Crypt.";
    };

    projectile.importTargets = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Directories and glob patterns from which Projectile should import projects.
        Directories are searched recursively, while glob matches are treated as
        exact project candidates.
      '';
    };
  };

  doomPrivateConfig =
    if isDarwin then
      config.modules.editors.emacs.doom
    else
      config.home-manager.users.${config.user.name}.modules.editors.emacs.doom;

  doomProjectileImportTargets = "(${
    concatMapStringsSep " " builtins.toJSON doomPrivateConfig.projectile.importTargets
  })";

  doomFramework = pkgs.runCommand "doom-emacs" { } ''
    mkdir -p "$out/sources"
    cp -R ${inputs.doom-emacs}/. "$out/"
    chmod -R u+w "$out"
    rm -rf "$out/sources/doom+"
    cp -R ${inputs.doom-emacs-modules} "$out/sources/doom+"

    # Doom still falls back to $EMACSDIR/.local when DOOMLOCALDIR is absent.
    # Keep GUI launches safe even on platforms that do not inherit a shell
    # environment, while the wrapper and activation use DOOMLOCALDIR directly.
    rm -rf "$out/.local"
    ln -s ${escapeShellArg doomEnvironment.DOOMLOCALDIR} "$out/.local"

    ${optionalString isDarwin ''
      mv "$out/early-init.el" "$out/early-init.doom.el"
      cp ${
        pkgs.replaceVars ../../../config/emacs/doom/darwin/early-init.el {
          environmentFile = "${homeManagerConfig.xdg.configHome}/environment.d/emacs.sh";
          gccMajorVersion = pkgs.my.emacs-plus-darwin.gccMajorVersion;
          homebrewBin = "${pkgs.my.emacs-plus-darwin.homebrewPrefix}/bin";
        }
      } "$out/early-init.el"
    ''}
  '';

  enabled = condition: name: {
    inherit condition name;
    flags = [ ];
  };

  enabledWithFlags = condition: name: flags: {
    inherit condition name flags;
  };

  always = name: enabled true name;
  alwaysWithFlags = name: flags: enabledWithFlags true name flags;

  languageModule =
    name: languageEnabled: languageServerEnabled:
    enabledWithFlags languageEnabled name (optionals languageServerEnabled [ "+lsp" ]);

  doomSections = [
    {
      name = "completion";
      modules = [
        (alwaysWithFlags "corfu" [ "+orderless" ])
        (always "vertico")
      ];
    }
    {
      name = "ui";
      modules =
        map always [
          "doom"
          "dashboard"
          "doom-quit"
          "hl-todo"
          "modeline"
          "nav-flash"
          "neotree"
          "ophints"
        ]
        ++ [ (alwaysWithFlags "popup" [ "+defaults" ]) ]
        ++ map always [
          "vc-gutter"
          "vi-tilde-fringe"
          "window-select"
          "workspaces"
          "zen"
        ];
    }
    {
      name = "editor";
      modules = [
        (alwaysWithFlags "evil" [ "+everywhere" ])
        (always "file-templates")
        (always "fold")
        (alwaysWithFlags "format" [ "+onsave" ])
        (always "snippets")
      ];
    }
    {
      name = "emacs";
      modules = map always [
        "dired"
        "electric"
        "undo"
        "vc"
      ];
    }
    {
      name = "term";
      modules = [ (always "shell") ];
    }
    {
      name = "checkers";
      modules = [
        (always "syntax")
        (alwaysWithFlags "spell" [ "+aspell" ])
      ];
    }
    {
      name = "tools";
      modules = [
        (enabled config.modules.networking.ansible.enable "ansible")
        (enabled config.modules.shell.direnv.enable "direnv")
        (enabled (attrByPath [
          "modules"
          "virtualization"
          "docker"
          "enable"
        ] false config) "docker")
        (always "editorconfig")
        (alwaysWithFlags "eval" [ "+overlay" ])
        (always "lookup")
        (enabled (any (languageServerEnabled: languageServerEnabled) [
          (config.modules.development.cc.enable && config.modules.development.cc.languageServer.enable)
          (config.modules.development.go.enable && config.modules.development.go.languageServer.enable)
          (config.modules.development.lua.enable && config.modules.development.lua.languageServer.enable)
          (config.modules.development.node.enable && config.modules.development.node.languageServer.enable)
          (
            config.modules.development.python.enable && config.modules.development.python.languageServer.enable
          )
          (config.modules.development.rust.enable && config.modules.development.rust.languageServer.enable)
        ]) "lsp")
        (always "magit")
        (enabled config.modules.networking.terraform.enable "terraform")
      ];
    }
    {
      name = "lang";
      modules = [
        (languageModule "cc" config.modules.development.cc.enable
          config.modules.development.cc.languageServer.enable
        )
        (enabled config.modules.development.clisp.enable "common-lisp")
        (always "data")
        (enabledWithFlags config.modules.development.flutter.enable "dart" [ "+flutter" ])
        (enabled config.modules.development.elixir.enable "elixir")
        (always "emacs-lisp")
        (languageModule "go" config.modules.development.go.enable
          config.modules.development.go.languageServer.enable
        )
        (enabled config.modules.development.java.enable "java")
        (languageModule "javascript" config.modules.development.node.enable
          config.modules.development.node.languageServer.enable
        )
        (languageModule "lua" config.modules.development.lua.enable
          config.modules.development.lua.languageServer.enable
        )
        (always "markdown")
        (always "nix")
        (alwaysWithFlags "org" [
          "+crypt"
          "+roam"
          "+journal"
          "+dragndrop"
          "+pandoc"
          "+present"
        ])
        (languageModule "python" config.modules.development.python.enable
          config.modules.development.python.languageServer.enable
        )
        (enabled config.modules.development.ruby.enable "ruby")
        (languageModule "rust" config.modules.development.rust.enable
          config.modules.development.rust.languageServer.enable
        )
        (always "sh")
        (always "yaml")
      ];
    }
    {
      name = "config";
      modules = [
        (alwaysWithFlags "default" [
          "+bindings"
          "+smartparens"
        ])
      ];
    }
  ];

  renderDoomModule =
    module:
    if module.flags == [ ] then
      module.name
    else
      "(${module.name} ${concatStringsSep " " module.flags})";

  renderDoomSection =
    section:
    let
      enabledModules = filter (module: module.condition) section.modules;
    in
    ''
             :${section.name}
      ${concatMapStringsSep "\n" (module: "       ${renderDoomModule module}") enabledModules}'';

  doomInitText = ''
    ;;; init.el -*- lexical-binding: t; -*-
    ${generatedFileWarning {
      file = ./doom.nix;
      comment = ";;";
    }}

    (doom!
    ${concatMapStringsSep "\n" renderDoomSection doomSections})
  '';

  doomConfigText = ''
    ;;; config.el -*- lexical-binding: t; -*-
    ${generatedFileWarning {
      file = ./doom.nix;
      comment = ";;";
    }}
    (setq user-full-name ${builtins.toJSON doomPrivateConfig.identity.fullName}
          user-mail-address ${builtins.toJSON doomPrivateConfig.identity.email}
          doom-font
          (font-spec :family ${builtins.toJSON config.modules.editors.emacs.font.family}
                     :size ${toString config.modules.editors.emacs.font.size}))

    ;; Keep mutable Customize output outside the Nix-managed Doom directory.
    (setq custom-file (expand-file-name "custom.el" doom-state-dir))

    ${builtins.readFile ../../../config/emacs/doom/config.el}

    (after! projectile
      (defun mc/projectile--add-project (directory)
        "Add DIRECTORY when it is itself a Projectile project root."
        (when (file-directory-p directory)
          (let* ((directory (file-name-as-directory (file-truename directory)))
                 (project-root (projectile-project-root directory)))
            (when (and project-root (file-equal-p directory project-root))
              (projectile-add-known-project directory)
              t))))

      (defun mc/projectile--import-project-tree (directory visited)
        "Import projects below DIRECTORY, avoiding paths in VISITED."
        (when (file-directory-p directory)
          (let ((directory (file-name-as-directory (file-truename directory))))
            (unless (gethash directory visited)
              (puthash directory t visited)
              (unless (mc/projectile--add-project directory)
                (dolist (child (directory-files directory t "\\`[^.]" t))
                  (when (file-directory-p child)
                    (mc/projectile--import-project-tree child visited))))))))

      (defun mc/projectile-import-projects (&optional targets)
        "Import Projectile projects from directory and glob TARGETS."
        (let ((visited (make-hash-table :test #'equal)))
          (dolist (target (or targets '()))
            (let ((target (expand-file-name target)))
              (if (string-match-p "[][?*]" target)
                  (dolist (candidate (file-expand-wildcards target t))
                    (mc/projectile--add-project candidate))
                (mc/projectile--import-project-tree target visited))))))

      (mc/projectile-import-projects
       '${doomProjectileImportTargets}))

    ${optionalString config.modules.development.python.enable ''
      ;; Keep the existing autopep8 behavior while Doom owns Apheleia lifecycle.
      (after! python
        (set-formatter! 'autopep8 '("autopep8" "-")
          :modes '(python-mode python-ts-mode)))
    ''}
    ${optionalString
      (
        config.modules.development.python.enable && config.modules.development.python.languageServer.enable
      )
      ''
        ;; Zuban is installed by modules.development.python.languageServer.
        (after! lsp-mode
          (lsp-register-client
           (make-lsp-client
            :new-connection (lsp-stdio-connection '("zuban" "server"))
            :activation-fn (lsp-activate-on "python")
            :major-modes '(python-mode python-ts-mode)
            :priority 2
            :server-id 'zuban)))
      ''
    }
    ${optionalString config.modules.development.lua.enable ''
      (add-hook 'lua-mode-hook
                (defun mc/lua-use-tabs-h ()
                  "Use tabs in Lua buffers."
                  (setq-local indent-tabs-mode t)))
    ''}
  '';

  doomPackagesText = ''
    ;;; packages.el -*- no-byte-compile: t; -*-
    ${generatedFileWarning {
      file = ./doom.nix;
      comment = ";;";
    }}
    ${builtins.readFile ../../../config/emacs/doom/packages.el}
  '';

  doomOrgText = ''
    ;;; org.el -*- lexical-binding: t; -*-
    ${generatedFileWarning {
      file = ./doom.nix;
      comment = ";;";
    }}
    (setq org-crypt-key ${builtins.toJSON doomPrivateConfig.org.cryptKey})

    ${builtins.readFile ../../../config/emacs/doom/org.el}
  '';

  doomConfiguration = pkgs.runCommand "doom-configuration" { } ''
    mkdir -p "$out/themes"
    cp ${pkgs.writeText "doom-init.el" doomInitText} "$out/init.el"
    cp ${pkgs.writeText "doom-config.el" doomConfigText} "$out/config.el"
    cp ${pkgs.writeText "doom-org.el" doomOrgText} "$out/org.el"
    cp ${pkgs.writeText "doom-packages.el" doomPackagesText} "$out/packages.el"
    cp ${../../../config/emacs/doom/themes/doom-retrowave-theme.el} \
      "$out/themes/doom-retrowave-theme.el"
  '';

  doomPackages = with pkgs; [
    (ripgrep.override { withPCRE2 = true; })
    (aspellWithDicts (dictionaries: [ dictionaries.en ]))
    editorconfig-core-c
    fd
    gnutls
    gnupg
    graphviz
    pandoc
    shfmt
    sqlite
    zstd
  ];

  doomNodePackages = optionals config.modules.development.node.enable [
    pkgs.prettier
  ];

  doomSyncCommands =
    if isDarwin then
      {
        cmp = "/usr/bin/cmp";
        install = "/usr/bin/install";
        mkdir = "/bin/mkdir";
      }
    else
      {
        cmp = "${pkgs.coreutils}/bin/cmp";
        install = "${pkgs.coreutils}/bin/install";
        mkdir = "${pkgs.coreutils}/bin/mkdir";
      };

  # Emacs+'s native compiler invokes Apple's assembler by its unqualified name.
  doomSyncSystemPath = optionalString isDarwin ":/usr/bin:/bin";

  doomIconFontPackages = with pkgs; [
    nerd-fonts.symbols-only
    emacs-all-the-icons-fonts
  ];

  doomSyncFingerprint = pkgs.writeText "doom-sync-fingerprint" ''
    framework=${doomFramework}
    configuration=${doomConfiguration}
    emacs=${config.modules.editors.emacs.package}
  '';

  doomSyncActivation = homeManagerLib.dag.entryAfter [ "installPackages" ] ''
    ${shellExports doomEnvironment}
    export EMACS="${config.modules.editors.emacs.package}/bin/emacs"
    export PATH="${
      makeBinPath (
        [
          config.modules.editors.emacs.package
          pkgs.git
        ]
        ++ doomPackages
        ++ doomNodePackages
      )
    }${doomSyncSystemPath}:$PATH"

    doomSyncState="$XDG_STATE_HOME/doom/nix-sync-fingerprint"
    if ! ${doomSyncCommands.cmp} -s ${doomSyncFingerprint} "$doomSyncState" \
      || [ ! -s "$DOOMLOCALDIR/cache/profiles._default.el" ] \
      || [ ! -s "$DOOMPROFILELOADFILE" ]; then
      echo "Synchronizing the Nix-managed Doom configuration"
      run ${doomFramework}/bin/doom sync --force

      if [[ ! -v DRY_RUN ]]; then
        if [ ! -s "$DOOMLOCALDIR/cache/profiles._default.el" ] \
          || [ ! -s "$DOOMPROFILELOADFILE" ]; then
          echo "Doom synchronization did not produce a bootable profile" >&2
          exit 1
        fi
      fi

      run ${doomSyncCommands.mkdir} -p "$XDG_STATE_HOME/doom"
      run ${doomSyncCommands.install} -m 0600 \
        ${doomSyncFingerprint} "$doomSyncState"
    fi
  '';

in
{
  options.modules.editors.emacs.doom = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to install the pinned Doom framework and render its configuration.";
    };
  }
  // doomPrivateOptions;

  config = mkMerge [
    (optionalAttrs (!isDarwin) {
      home-manager.users.${config.user.name}.imports = [
        {
          options.modules.editors.emacs.doom = doomPrivateOptions;
        }
      ];
    })

    (mkIf (config.modules.editors.emacs.enable && config.modules.editors.emacs.doom.enable) (mkMerge [
      {
        modules.editors.emacs.runtimeEnvironment = doomEnvironment;
      }

      (platformEnv {
        inherit config isDarwin;
        inherit shellExports;
        envVars = doomEnvironment;
        target = "both";
      })

      (platformPath {
        inherit config isDarwin;
        paths = [ (xdg.concrete.config "emacs/bin") ];
        target = "both";
      })
      (optionalAttrs (!isDarwin) {
        systemd.services."home-manager-${config.user.name}".serviceConfig.TimeoutStartSec = mkForce "30m";

        user.packages =
          doomPackages
          ++ doomNodePackages
          ++ [
            pkgs.scrot
            pkgs.xclip
          ]
          ++ optionals config.programs.gnupg.agent.enable [ pkgs.pinentry_emacs ];

        home.configFile = {
          "emacs".source = doomFramework;
          "doom".source = doomConfiguration;
        };

        home-manager.users.${config.user.name}.home.activation.syncDoom = doomSyncActivation;

        fonts.packages = doomIconFontPackages;
      })

      (optionalAttrs isDarwin (
        let
          nerdSymbolsFontDir = "${pkgs.nerd-fonts.symbols-only}/share/fonts/truetype/NerdFonts/Symbols";
          allTheIconsFontDir = "${pkgs.emacs-all-the-icons-fonts}/share/fonts/all-the-icons";

          emacsIconFontLinks = builtins.listToAttrs (
            map
              (fontFile: {
                name = "Library/Fonts/${fontFile.name}";
                value.source = fontFile.source;
              })
              [
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
              ]
          );
        in
        {
          home = {
            packages = [
              pkgs.fontconfig
              pkgs.pngpaste
            ]
            ++ doomPackages
            ++ doomNodePackages
            ++ doomIconFontPackages;

            file = emacsIconFontLinks;
            activation.syncDoom = doomSyncActivation;
          };

          xdg.configFile = {
            "emacs".source = doomFramework;
            "doom".source = doomConfiguration;
            "environment.d/emacs.sh".text =
              let
                baseEnvironmentNames = [
                  "XDG_BIN_HOME"
                  "XDG_CACHE_HOME"
                  "XDG_CONFIG_HOME"
                  "XDG_DATA_HOME"
                  "XDG_STATE_HOME"
                ];
                sessionVariables = homeManagerConfig.home.sessionVariables;
              in
              ''
                #!/bin/sh
                ${generatedFileWarning { file = ./doom.nix; }}
                ${shellExports (filterAttrs (name: _: elem name baseEnvironmentNames) sessionVariables)}
                ${shellExports (removeAttrs sessionVariables baseEnvironmentNames)}
                export PATH=${
                  escapeShellArg (
                    concatStringsSep ":" (
                      unique (
                        [
                          "${pkgs.my.emacs-plus-darwin.homebrewPrefix}/bin"
                          "${pkgs.my.emacs-plus-darwin.homebrewPrefix}/sbin"
                        ]
                        ++ map toString homeManagerConfig.home.sessionPath
                        ++ [
                          xdg.concrete.binHome
                          "${homeManagerConfig.home.profileDirectory}/bin"
                          "/nix/var/nix/profiles/default/bin"
                          "/usr/local/bin"
                          "/usr/bin"
                          "/bin"
                          "/usr/sbin"
                          "/sbin"
                        ]
                      )
                    )
                  )
                }
                exec /usr/bin/env -0
              '';
          };
        }
      ))
    ]))
  ];
}
