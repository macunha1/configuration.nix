{ config, options, lib, pkgs, ... }:

with lib;
{
  options.modules.shell.gnupg = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.gnupg.enable {
    my = {
      # env.GNUPGHOME = "$XDG_CONFIG_HOME/gpg";
    };

    programs.gnupg.agent = {
      enable = true;
      pinentryFlavor = "curses";
    };
  };
}
