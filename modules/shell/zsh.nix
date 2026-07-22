# shell/zsh.nix -- https://www.zsh.org
#
# ZSH, Oh my dear and loved ZSH. There are simply no words that would make
# justice to how good you are.
#
# Linux and Darwin: zsh managed declaratively with Nix-fetched plugins.

{
  config,
  options,
  pkgs,
  lib,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:
with lib;
# lib.my (configDir etc.) is present on NixOS; absent in standalone home-manager.
# The Darwin sections never access configDir, so the empty fallback is safe.
with (lib.my or { });

let
  # Some standalone evaluations pass plain nixpkgs.lib, so lib.my may be absent.
  # Import the generator directly in that case.
  inherit (lib.my or (import ../../lib/generators.nix { inherit lib pkgs; }))
    generatedFileWarning
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  # CLI utilities installed on both platforms.
  # Linux also adds pkgs.zsh itself; Darwin gets zsh from the system or nix-darwin.
  commonCliPackages = with pkgs; [
    starship # Spaceship prompt reimplemented in Rust
    htop # colorful top
    tldr # short man pages
    tree # directory tree view
    ripgrep # fast grep (also used by Doom Emacs)
    stow # GNU Stow, symlink manager
    jq # JSON for the shell
    fastfetch # system info banner (neofetch successor)
    keychain # SSH/GPG agent lifecycle manager
    sops # encrypted secrets editor
  ];

  # Syntax-highlighting theme - defined once, consumed by both platforms.
  zshHighlighters = [
    "main"
    "brackets"
    "line"
    "cursor"
  ];

  zshHighlightStyles = {
    "bracket-level-1" = "fg=14";
    "bracket-level-2" = "fg=13,bold";
    "bracket-level-3" = "fg=4";
    "bracket-level-4" = "fg=10,bold";
    alias = "fg=14";
    command = "fg=10,bold";
    function = "fg=10";
    arg0 = "fg=10,bold";
    autodirectory = "fg=4,underline";
    "bracket-error" = "fg=9,bold";
    "dollar-quoted-argument" = "fg=9";
    "double-quoted-argument" = "fg=9,bold";
    precommand = "fg=14,underline";
    redirection = "fg=10";
    "reserved-word" = "fg=10";
    "single-quoted-argument" = "fg=10";
    "suffix-alias" = "fg=14,underline";
  };

  # Shell code that initialises the highlighting variables for NixOS.
  # typeset -A is required before the (key value ...) assignment form.
  syntaxHighlightingEnv =
    let
      highlightersLine = concatStringsSep " " zshHighlighters;
      styleLines = mapAttrsToList (k: v: "  ${k} '${v}'") zshHighlightStyles;
    in
    ''
      ZSH_HIGHLIGHT_HIGHLIGHTERS=(${highlightersLine})
      typeset -A ZSH_HIGHLIGHT_STYLES
      ZSH_HIGHLIGHT_STYLES=(
      ${concatStringsSep "\n" styleLines}
      )
    '';

  zshPluginSources = {
    autosuggestions = "${pkgs."zsh-autosuggestions"}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";
    syntaxHighlighting = "${pkgs."zsh-syntax-highlighting"}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
  };

  zshPluginBeforeInit = ''
    source "${zshPluginSources.autosuggestions}"
  '';

  zshPluginAfterInit = ''
    source "${zshPluginSources.syntaxHighlighting}"
  '';

  zshAliasLines = concatStringsSep "\n" (
    mapAttrsToList (n: v: "alias '${n}'='${v}'") config.modules.shell.zsh.aliases
  );

  zshInitText = ''
    #!/usr/bin/env zsh
    #
    ${generatedFileWarning { file = ./zsh.nix; }}
    ${config.modules.shell.zsh.init}
  '';

  zshEnvText = ''
    #!/usr/bin/env zsh
    #
    ${generatedFileWarning { file = ./zsh.nix; }}
    export PATH="${xdg.shell.binHome}:$PATH"
    ${config.modules.shell.zsh.env}

    # Source per-user profile fragments - analogous to /etc/profile.d/.
    # Previously a separate .zprofile; inlined here so the file tree
    # stays clean and there is one authoritative place to read.
    if [[ -d "$HOME/.profile.d" ]]; then
      for i in "$HOME"/.profile.d/*.sh; do
        [[ -x "$i" ]] && source "$i"
      done
    fi
  '';

  # Tool completions - sourced after init.zsh, conditional on module flags.
  # kubectl completion is handled by the kubectl plugin (with caching); only
  # minikube and helm need explicit sourcing here.
  completionSources = concatStrings [
    (optionalString config.modules.networking.kubernetes.minikube.enable ''
      source <(minikube completion zsh)
    '')
    (optionalString config.modules.networking.kubernetes.helm.enable ''
      source <(helm completion zsh)
    '')
  ];

  urlEncodeCommand =
    "python3 -c " + ''"import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))"'';

  urlDecodeCommand =
    "python3 -c " + ''"import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))"'';

  # Key bindings - identical on both platforms (NixOS and MacOS).
  #
  # Ctrl+Y is used for `kill-line` instead of the default Ctrl+K to avoid
  # conflicting with Tmux Vim navigation keybinds (Ctrl+H,J,K,L). Y was picked
  # because it stand right next to U (default backward-kill-line).
  #
  # select-word-style bash: word chars = alphanumeric + underscore only, so Ctrl+W stops
  # at slashes, dashes, dots and other separators (matches the old OMZ Ctrl+W behaviour).
  #
  # up-line-or-beginning-search: arrow-up searches history by the prefix already typed
  # rather than walking commands in chronological order (matches OMZ history-search plugin).
  # terminfo keys are used so the binding works across terminals and over SSH.
  #
  # Ctrl+Q push-line: temporarily queues the current command line, presents a fresh
  # prompt, then restores the queued line after the next command completes.
  zshCompletionInit = ''
    autoload -U compinit && compinit -i
  '';

  shellBindings = runCompinit: ''
    stty -ixon

    bindkey -e
    bindkey '^U' backward-kill-line
    bindkey '^Y' kill-line
    bindkey '^Q' push-line
    bindkey '^[[3~' delete-char
    [[ -n "''${terminfo[kdch1]}" ]] && bindkey "''${terminfo[kdch1]}" delete-char

    ${optionalString runCompinit zshCompletionInit}
    autoload -U +X bashcompinit && bashcompinit
    autoload -U select-word-style
    select-word-style bash

    autoload -U up-line-or-beginning-search down-line-or-beginning-search
    zle -N up-line-or-beginning-search
    zle -N down-line-or-beginning-search
    bindkey '^[[A' up-line-or-beginning-search
    bindkey '^[[B' down-line-or-beginning-search
    [[ -n "''${terminfo[kcuu1]}" ]] && bindkey "''${terminfo[kcuu1]}" up-line-or-beginning-search
    [[ -n "''${terminfo[kcud1]}" ]] && bindkey "''${terminfo[kcud1]}" down-line-or-beginning-search
  '';

  # Keychain agent init - dir is platform-specific.
  keychainInit = dir: ''
    eval "$(keychain --dir "${dir}/keychain" -q --eval || ssh-agent)" >/dev/null
  '';

in
{
  options.modules.shell.zsh = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    # Cross-platform alias collection; other modules append here.
    aliases =
      with types;
      mkOption {
        type = attrsOf (oneOf [
          str
          path
          (listOf (either str path))
        ]);
        apply = mapAttrs (
          n: v: if isList v then concatMapStringsSep ":" (x: toString x) v else (toString v)
        );
        default = { };
        description = "Shell aliases written into zsh/init.zsh on both platforms.";
      };

    # Extra shell lines appended into init.zsh on both platforms.
    init = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Zsh lines to insert into $XDG_CONFIG_HOME/zsh/init.zsh.
        These run after env.zsh and before plugin sourcing.
      '';
    };

    # Extra lines written into env.zsh on both platforms.
    # Modules contribute here; zsh.nix renders the result to
    # $XDG_CONFIG_HOME/zsh/env.zsh (home.configFile on Linux,
    # xdg.configFile on Darwin).
    env = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Zsh lines to insert into $XDG_CONFIG_HOME/zsh/env.zsh.
        Sourced before init.zsh on both platforms.
      '';
    };

    historySize = mkOption {
      type = types.int;
      default = 9223372036854775807; # LONG_MAX: Unlimited
    };
  };

  config = mkIf config.modules.shell.zsh.enable (mkMerge [
    {
      modules.shell.zsh.aliases.l = mkDefault "ls --color=auto -lah";
    }

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) (mkMerge [
      {
        # Set ZSH as the default for users; even Apple is doing it now
        users.defaultUserShell = pkgs.zsh;

        programs.zsh = {
          enable = true;
          enableCompletion = true;
          enableGlobalCompInit = false;
          histSize = config.modules.shell.zsh.historySize;
        };

        user.packages = [ pkgs.zsh ] ++ commonCliPackages;

        # ZSH XDG paths - dotfiles live under $XDG_CONFIG_HOME/zsh
        env.ZDOTDIR = xdg.shell.config "zsh";
        env.ZSH_CACHE = xdg.shell.cache "zsh";

        # Write variables down to ZSH files
        home.configFile = {
          "zsh/.zshrc".text = ''
            #!/usr/bin/env zsh
            #
            ${generatedFileWarning { file = ./zsh.nix; }}

            source "$HOME/.config/zsh/env.zsh"
            ${zshPluginBeforeInit}
            source "$HOME/.config/zsh/init.zsh"
            ${completionSources}
            ${zshPluginAfterInit}
          '';

          "zsh/init.zsh".text = ''
            ${zshInitText}

            ${zshAliasLines}
          '';

          "zsh/env.zsh".text = zshEnvText;
        };

        home.configFile."starship.toml" = {
          source = "${configDir}/starship/config.toml";
        };

        # Syntax-highlight vars must be set in env.zsh before the plugin is sourced.
        modules.shell.zsh.env = syntaxHighlightingEnv;

        # Clipboard, URL encode/decode - mirror of the Darwin programs.zsh.shellAliases.
        # xclip replaces pbcopy/pbpaste on Linux.
        environment.shellAliases = {
          urlencode = urlEncodeCommand;
          urldecode = urlDecodeCommand;
          clipbc = ''xclip -in -selection clipboard < "''${1:-/dev/stdin}"'';
          clipbp = "xclip -out -selection clipboard";
        };

        # Shell init - goes into init.zsh, sourced from .zshrc after plugins load.
        modules.shell.zsh.init = ''
          setopt NO_SHARE_HISTORY APPEND_HISTORY HIST_FCNTL_LOCK
          ${shellBindings true}
          ${keychainInit xdg.shell.configHome}
          eval "$(starship init zsh)"
        '';
      }
    ]))

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      home.packages = commonCliPackages;

      # ~/.local/bin is exported via modules.shell.zsh.env below so it is available
      # in all interactive shells, not just login shells.

      programs.zsh = {
        enable = true;
        enableCompletion = true;
        completionInit = zshCompletionInit;
        dotDir = xdg.concrete.config "zsh";

        history = {
          size = config.modules.shell.zsh.historySize;
          path = xdg.concrete.state "zsh/history";
          share = false;
        };

        # macOS-only aliases. Cross-platform aliases live in init.zsh (generated
        # from modules.shell.zsh.aliases) so they follow the same path as NixOS.
        shellAliases = {
          urlencode = urlEncodeCommand;
          urldecode = urlDecodeCommand;
          clipbc = "pbcopy";
          clipbp = "pbpaste";
        };

        initContent = mkMerge [
          # Source env.zsh before completions so PATH, XDG vars, and brew are
          # already set when the plugins initialise.
          (mkOrder 550 ''
            source "${xdg.concrete.config "zsh/env.zsh"}"
          '')

          ''
            setopt NO_SHARE_HISTORY APPEND_HISTORY HIST_FCNTL_LOCK
            ${zshPluginBeforeInit}
            ${shellBindings false}
            ${keychainInit xdg.concrete.configHome}
            source "${xdg.concrete.config "zsh/init.zsh"}"
            ${completionSources}
            ${zshPluginAfterInit}
          ''
        ];
      };

      # Darwin-specific env.zsh content: brew path setup and GPG_TTY.
      # brew shellenv must run before completions so Homebrew binaries are in PATH.
      # GPG_TTY must be set per-session (not via home.sessionVariables, login-only).
      modules.shell.zsh.env = ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
        export GPG_TTY=$(tty)
      '';

      xdg.configFile."zsh/env.zsh".text = zshEnvText;

      xdg.configFile."zsh/init.zsh".text = ''
        ${zshInitText}

        ${zshAliasLines}
      '';

      programs.starship = {
        enable = true;
        enableZshIntegration = true;
        settings = builtins.fromTOML (builtins.readFile ../../config/starship/config.toml);
      };
    })
  ]);
}
