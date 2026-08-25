# shell/tmux.nix -- https://github.com/tmux/tmux
#
# Tmux, Vim and ZSH are the combo of productivity. You don't think you even
# need Tmux until you learn to use it and then there's no turnback.
#
# Tmux multi panel, background sessions that you detach and attach and the
# multiplexer are god sends.
#
# Linux: tmux.conf and Nix-pinned plugins managed declaratively.
#
# Darwin: programs.tmux and the same Nix-pinned plugins managed by Home Manager.

{
  config,
  pkgs,
  lib,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:

with lib;

let
  # Some standalone evaluations pass plain nixpkgs.lib, so lib.my may be absent.
  # Import the generator directly in that case.
  inherit (lib.my or (import ../../lib/generators.nix { inherit lib pkgs; }))
    generatedFileWarning
    ;

  tmuxPlugins = {
    inherit (pkgs.tmuxPlugins)
      resurrect
      sensible
      sysstat
      ;
  };

  pluginScript = name: "${tmuxPlugins.${name}}/share/tmux-plugins/${name}/${name}.tmux";

  tmuxAliases = {
    t = "tmux";
  };

  # Keep final tmux behavior identical after platform-specific module defaults
  # and tmux-sensible have been applied.
  sharedOptions = ''
    set -g default-terminal "screen-256color"
    set -g base-index 1
    set -g pane-base-index 1

    set -g status-keys vi
    set -g mode-keys vi
    set -g clock-mode-style 24

    set -s escape-time 0
    set -g history-limit 10000
    set -g focus-events on
    set -wg aggressive-resize on

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

  # Status bar left/right content. Keep this separate because sysstat.tmux
  # string-replaces #{sysstat_cpu}/#{sysstat_mem} in status-right at load
  # time; those options must already be set before the plugin runs.
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

  resurrectConfig = "set -g @resurrect-strategy-nvim 'session'";
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
      user.packages = [ pkgs.tmux ];

      environment.shellAliases = tmuxAliases;

      home.configFile."tmux/tmux.conf".text = ''
        ${generatedFileWarning { file = ./tmux.nix; }}

        run-shell "${pluginScript "sensible"}"

        ${sharedOptions}
        ${sysstatConfig}
        ${statusConfig}
        ${vimAwareNavigation}
        ${splitBindings}
        ${copyModeBindings "xclip -i -selection clipboard"}

        run-shell "${pluginScript "sysstat"}"
        ${resurrectConfig}
        run-shell "${pluginScript "resurrect"}"
      '';
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      modules.shell.zsh.aliases = tmuxAliases;

      programs.tmux = {
        enable = true;
        sensibleOnTop = true;

        plugins = [
          {
            plugin = tmuxPlugins.sysstat;
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
            plugin = tmuxPlugins.resurrect;
            extraConfig = resurrectConfig;
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
  ]);
}
