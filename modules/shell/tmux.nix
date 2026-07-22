# shell/tmux.nix -- https://github.com/tmux/tmux
#
# Tmux, Vim and ZSH are the combo of productivity. You don't think you even
# need Tmux until you learn to use it and then there's no turnback.
#
# Tmux multi panel, background sessions that you detach and attach and the
# multiplexer are god sends.
#
# Linux: wrapper script to force XDG config path + TPM plugin manager.
#        tmux.conf generated from Nix; shared variables below keep both platforms in sync.
#
# Darwin: programs.tmux managed declaratively by home-manager (no TPM needed).

{
  config,
  options,
  pkgs,
  lib,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

with lib;
with (lib.my or { });

let
  # Some standalone evaluations pass plain nixpkgs.lib, so lib.my may be absent.
  # Import the generator directly in that case.
  inherit (lib.my or (import ../../lib/generators.nix { inherit lib pkgs; }))
    generatedFileWarning
    shellExports
    ;

  inherit (lib.my or (import ../../lib/modules.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  tmuxAliases = {
    t = "tmux";
  };

  tmuxEnvVars = {
    TMUX_HOME = xdg.concrete.config "tmux";
    TMUX_PLUGIN_MANAGER_PATH = xdg.concrete.config "tmux/plugins";
  };

  # Display and style settings not exposed as programs.tmux declarative options.
  # Applied via extraConfig on Darwin; included verbatim in tmux.conf on Linux.
  sharedOptions = ''
    set -g status on
    set -g status-interval 8
    set -g status-justify centre
    set -g status-position top
    set -g status-style bg=black,fg=colour9

    set -g pane-active-border-style bg=default,fg=colour14
    set -g pane-border-style bg=default,fg=colour9

    set -g message-style bg=black,bold,fg=colour9

    set -g window-status-current-style fg=colour10,bold
    set -g mode-style reverse
  '';

  # tmux-plugin-sysstat (samoshkin/tmux-plugin-sysstat) display templates.
  sysstatConfig = ''
    set -g @sysstat_cpu_view_tmpl 'CPU: #{cpu.pused}'
    set -g @sysstat_mem_view_tmpl 'RAM: #{mem.used} / #{mem.total}'
  '';

  # Status bar left/right content - kept separate because sysstat.tmux
  # string-replaces #{sysstat_cpu}/#{sysstat_mem} in status-right at load
  # time; those options must already be set before the plugin runs.
  #
  # On Darwin, placing this in the sysstat plugin's extraConfig guarantees
  # it lands before the run-shell line. On Linux, TPM runs all plugins last
  # so ordering within the config file does not matter.
  statusConfig = ''
    set -g status-right-length 100
    set -g status-right "#[fg=colour14][ #{sysstat_cpu} | #{sysstat_mem} | %H:%M %A %d/%m/%Y ]"

    set -g status-left-length 100
    set -g status-left "#[fg=colour14][ #S | #(echo $USER) @ #H ]"
  '';

  # Vim-aware pane navigation - no prefix required.
  # If the current pane is running Vim the keystroke is forwarded to it;
  # otherwise tmux's own select-pane is used.
  vimAwareNavigation = ''
    bind -n C-h run "(tmux display-message -p '#{pane_current_command}' | grep -iq vim && tmux send-keys C-h) || tmux select-pane -L"
    bind -n C-j run "(tmux display-message -p '#{pane_current_command}' | grep -iq vim && tmux send-keys C-j) || tmux select-pane -D"
    bind -n C-k run "(tmux display-message -p '#{pane_current_command}' | grep -iq vim && tmux send-keys C-k) || tmux select-pane -U"
    bind -n C-l run "(tmux display-message -p '#{pane_current_command}' | grep -iq vim && tmux send-keys C-l) || tmux select-pane -R"
    bind -n C-\\ run "(tmux display-message -p '#{pane_current_command}' | grep -iq vim && tmux send-keys 'C-\\') || tmux select-pane -l"
  '';

  # Splits that open in the current pane's working directory.
  # v = side-by-side (vertical split), s = stacked (horizontal split) - Vim mnemonics.
  splitBindings = ''
    bind -n C-v split-window -h -c "#{pane_current_path}"
    bind -n C-s split-window -v -c "#{pane_current_path}"
  '';

  # vi copy-mode keybindings parametrised by the platform clipboard command.
  copyModeBindings = clipCmd: ''
    unbind -T copy-mode-vi v
    unbind -T copy-mode-vi V
    unbind -T copy-mode-vi y

    bind-key -T copy-mode-vi v send-keys -X begin-selection
    bind-key -T copy-mode-vi V send-keys -X select-line
    bind-key -T copy-mode-vi y send-keys -X copy-pipe '${clipCmd}'
  '';
in
{
  options.modules.shell.tmux = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.tmux.enable (mkMerge [

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = with pkgs; [
        # Since Tmux doesn't support XDG spec, we force it with a wrapper
        (writeScriptBin "tmux" ''
          #!${stdenv.shell}
          ${generatedFileWarning { file = ./tmux.nix; }}
          exec ${tmux}/bin/tmux -f "$TMUX_HOME/tmux.conf" "$@"
        '')
      ];

      environment.shellAliases = tmuxAliases;

      # Following path from https://github.com/tmux-plugins/tpm
      home.configFile."tmux/plugins/tpm" = {
        source = pkgs.fetchFromGitHub {
          owner = "tmux-plugins";
          repo = "tpm";
          rev = "v3.0.0";
          sha256 = "18q5j92fzmxwg8g9mzgdi5klfzcz0z01gr8q2y9hi4h4n864r059";
        };
      };

      home.configFile."tmux/tmux.conf".text = ''
        ${generatedFileWarning { file = ./tmux.nix; }}
        # Plugins - TPM installs these on first run (prefix + I)
        set -g @tpm_plugins '\
          tmux-plugins/tpm \
          tmux-plugins/tmux-sensible \
          samoshkin/tmux-plugin-sysstat \
          tmux-plugins/tmux-resurrect \
        '

        set -g default-terminal "screen-256color"
        set -g base-index 1
        set -g pane-base-index 1

        set -g mode-keys vi

        ${sysstatConfig}
        ${statusConfig}
        ${sharedOptions}
        ${vimAwareNavigation}
        ${splitBindings}
        ${copyModeBindings "xclip -i -selection clipboard"}

        # Initialize TPM - must be the last line
        run -b "${xdg.shell.config "tmux/plugins/tpm/tpm"}"
      '';
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      modules.shell.zsh.aliases = tmuxAliases;

      programs.tmux = {
        enable = true;
        sensibleOnTop = true; # tmux-sensible: sane defaults first
        baseIndex = 1; # windows and panes start at 1, not 0
        clock24 = true;
        escapeTime = 0; # no delay after Escape (important for Vim/Emacs)
        historyLimit = 10000;
        keyMode = "vi";
        terminal = "screen-256color";

        plugins = with pkgs.tmuxPlugins; [
          sensible
          {
            plugin = sysstat; # samoshkin/tmux-plugin-sysstat
            #
            # statusConfig must come before sysstat.tmux runs: the plugin
            # string-replaces #{sysstat_cpu}/#{sysstat_mem} in status-right
            # at load time, so those options must already be set.
            extraConfig = ''
              ${sysstatConfig}
              ${statusConfig}
            '';
          }
          {
            plugin = resurrect; # persist sessions across restarts
            extraConfig = "set -g @resurrect-strategy-nvim 'session'";
          }
        ];

        extraConfig = ''
          ${sharedOptions}
          ${vimAwareNavigation}
          ${splitBindings}
          ${copyModeBindings "pbcopy"}
        '';
      };
    })

    # Mirror Linux env.TMUX_* assignments into Darwin env.zsh.
    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = tmuxEnvVars;
      darwinTarget = "zsh";
    })
  ]);
}
