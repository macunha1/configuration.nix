# shell/gnupg.nix -- https://gnupg.org/
#
# GNU Privacy Guard. The free (you know, GNU free is not about the price)
# implementation of OpenPGP standard for encrypting and signing data and
# communication estabilishing reliable and safe channels.
#
# Linux: user.packages; gpg-agent wired through the NixOS home-manager proxy;
#        gpg-agent.conf placed via home.configFile (custom NixOS option).
# Darwin: home.packages; gpg-agent managed directly by home-manager services;
#         gpg-agent.conf placed via xdg.configFile.
#
# Both platforms: GNUPGHOME set to $XDG_CONFIG_HOME/gpg; same gpg-agent.conf
# content (the pinentryPackage option is skipped in favour of the explicit
# pinentry-program line in the conf, which correctly respects GNUPGHOME).

{ config, options, lib, pkgs, isDarwin ? pkgs.stdenv.isDarwin, ... }:

with lib;

let
  # gpg-agent configuration - same content on both platforms.
  # Both home.configFile (Linux) and xdg.configFile (Darwin) consume this text.
  gpgAgentConf = ''
    default-cache-ttl ${toString config.modules.shell.gnupg.cacheTTL}
    pinentry-program ${config.modules.shell.gnupg.pinentry}/bin/pinentry
  '';
in {
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
      default =
        pkgs.pinentry-curses; # override to pinentry-mac on Darwin if preferred
    };

    cacheTTL = mkOption {
      type = types.int;
      default = 3600;
    };
  };

  config = mkIf config.modules.shell.gnupg.enable (mkMerge [

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = with pkgs; [ gnupg ];

      # home-manager.users.* is the NixOS proxy for per-user home-manager options
      home-manager.users.${config.user.name}.services.gpg-agent = {
        enable = true;
        enableSshSupport = config.modules.shell.gnupg.ssh.enable;
        defaultCacheTtl = config.modules.shell.gnupg.cacheTTL;
      };

      # pinentryFlavor/pinentryPackage doesn't respect GNUPGHOME, so we write
      # the pinentry-program line directly into the conf file instead
      home.configFile."gpg/gpg-agent.conf".text = gpgAgentConf;

      env.GNUPGHOME = "$XDG_CONFIG_HOME/gpg";
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      home.packages = with pkgs; [ gnupg ];

      services.gpg-agent = {
        enable = true;
        enableSshSupport = config.modules.shell.gnupg.ssh.enable;
        defaultCacheTtl = config.modules.shell.gnupg.cacheTTL;
      };

      xdg.configFile."gpg/gpg-agent.conf".text = gpgAgentConf;

      # home.sessionVariables does not expand shell-variable references at write time,
      # so "$XDG_CONFIG_HOME/gpg" would land as a literal string. Use env.zsh instead.
      modules.shell.zsh.env = ''
        export GNUPGHOME="${config.xdg.configHome}/gpg"
      '';
    })
  ]);
}
