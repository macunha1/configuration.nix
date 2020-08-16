{ config, options, lib, pkgs, ... }:

with lib; {
  options.modules.shell.gnupg = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.gnupg.enable {
    my = {
      home.services.gpg-agent = {
        enable = true;
        # Would be nice, but doesn't respect the XDG config
        # pinentryFlavor = "curses";
      };

      # Fallback for pinentryFlavor
      home.xdg.configFile."gpg/gpg-agent.conf" = {
        text = ''
          pinentry-program ${pkgs.pinentry-curses}/bin/pinentry
        '';
      };

      env.GNUPGHOME = "$XDG_CONFIG_HOME/gpg";
    };
  };
}
