# desktop/terminal -- default configuration among installations

{ config, options, lib, pkgs, ... }:

with lib; {
  options.modules.desktop.terminal = {
    default = mkOption {
      type = with types; nullOr str;
      default = null;
    };
  };

  config = mkIf (config.modules.desktop.terminal.default != null) {
    env.TERMINAL = config.modules.desktop.terminal.default;
  };
}
