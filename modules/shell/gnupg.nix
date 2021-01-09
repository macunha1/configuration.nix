# shell/gnupg.nix -- https://gnupg.org/
#
# GNU Privacy Guard. The free (you know, GNU free is not about the price)
# implementation of OpenPGP standard for encrypting and signing data and
# communication estabilishing reliable and safe channels.

{ config, options, lib, pkgs, ... }:

with lib; {
  options.modules.shell.gnupg = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.gnupg.enable {
    home-manager.users.${config.user.name}.services.gpg-agent = {
      enable = true;
      # Would be nice, but doesn't respect the XDG config
      # pinentryFlavor = "curses";
    };

    # Fallback for pinentryFlavor
    home.configFile."gpg/gpg-agent.conf" = {
      text = ''
        pinentry-program ${pkgs.pinentry-curses}/bin/pinentry
      '';
    };

    env.GNUPGHOME = "$XDG_CONFIG_HOME/gpg";
  };
}
