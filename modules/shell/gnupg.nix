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

{
  config,
  options,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

with lib;

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

  gnupgPackages = with pkgs; [
    gnupg
    gpgme
  ];

  gnupgEnvVars = {
    GNUPGHOME = xdg.concrete.config "gpg";
  };

  # gpg-agent configuration - same content on both platforms.
  # Both home.configFile (Linux) and xdg.configFile (Darwin) consume this text.
  gpgAgentConf = ''
    ${generatedFileWarning { file = ./gnupg.nix; }}
    default-cache-ttl ${toString config.modules.shell.gnupg.cacheTTL}
    max-cache-ttl ${toString config.modules.shell.gnupg.cacheTTL}
    pinentry-program ${config.modules.shell.gnupg.pinentry}/bin/pinentry
  '';
in
{
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
      default = pkgs.pinentry-curses; # override to pinentry-mac on Darwin if preferred
    };

    cacheTTL = mkOption {
      type = types.int;
      default = 21600;
    };
  };

  config = mkIf config.modules.shell.gnupg.enable (mkMerge [

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      # home-manager.users.* is the NixOS proxy for per-user home-manager options
      home-manager.users.${config.user.name}.services.gpg-agent = {
        enable = true;
        enableSshSupport = config.modules.shell.gnupg.ssh.enable;
        defaultCacheTtl = config.modules.shell.gnupg.cacheTTL;
        maxCacheTtl = config.modules.shell.gnupg.cacheTTL;
      };

      # pinentryFlavor/pinentryPackage doesn't respect GNUPGHOME, so we write
      # the pinentry-program line directly into the conf file instead
      home.configFile."gpg/gpg-agent.conf".text = gpgAgentConf;

    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      services.gpg-agent = {
        enable = true;
        enableSshSupport = config.modules.shell.gnupg.ssh.enable;
        defaultCacheTtl = config.modules.shell.gnupg.cacheTTL;
        maxCacheTtl = config.modules.shell.gnupg.cacheTTL;
      };

      xdg.configFile."gpg/gpg-agent.conf".text = gpgAgentConf;

    })

    (platformPackages {
      inherit isDarwin;
      packages = gnupgPackages;
    })

    # home.sessionVariables does not expand shell-variable references at write time,
    # so Darwin writes GNUPGHOME into env.zsh while NixOS uses the env option.
    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = gnupgEnvVars;
      darwinTarget = "zsh";
    })
  ]);
}
