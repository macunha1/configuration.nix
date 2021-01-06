{ config, options, lib, pkgs, ... }:
with lib; {
  imports = [ ./alacritty.nix ];

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
