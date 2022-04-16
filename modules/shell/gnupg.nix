# shell/gnupg.nix -- https://gnupg.org/
#
# GNU Privacy Guard. The free (you know, GNU free is not about the price)
# implementation of OpenPGP standard for encrypting and signing data and
# communication estabilishing reliable and safe channels.

{ config, home-manager, options, lib, pkgs, ... }:

with lib; {
  options.modules.shell.gnupg = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    ssh.enable = mkOption {
      type = types.bool;
      default = false;
    };

    pinentry = mkOption {
      type = types.package;
      default = pkgs.pinentry-curses;
    };

    cacheTTL = mkOption {
      type = types.int;
      default = 3600;
    };
  };

  config = mkIf config.modules.shell.gnupg.enable {
    user.packages = with pkgs; [ gnupg ];

    home-manager.users.${config.user.name}.services.gpg-agent = {
      enable = true;
      enableSshSupport = config.modules.shell.gnupg.ssh.enable;
      defaultCacheTtl = config.modules.shell.gnupg.cacheTTL;

      # Would be nice, but doesn't respect the XDG config
      # pinentryFlavor = "curses";
    };

    # Fallback for pinentryFlavor
    home.configFile."gpg/gpg-agent.conf" = {
      text = ''
        default-cache-ttl ${toString config.modules.shell.gnupg.cacheTTL}
        pinentry-program ${config.modules.shell.gnupg.pinentry}/bin/pinentry
      '';
    };

    env.GNUPGHOME = "$XDG_CONFIG_HOME/gpg";
  };
}
