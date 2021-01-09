# shell/pass.nix -- https://www.passwordstore.org/
#
# Simple CLI util that takes advantage of GNU Privacy Guards to encrypt files
# and store secrets locally. In-a-nutshell: a wrapper for 'gpg' with directory
# management for the encrypted content.

{ config, options, pkgs, lib, ... }:
with lib; {
  options.modules.shell.pass = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.pass.enable {
    user.packages = with pkgs; [
      (pass.withExtensions (exts: [ exts.pass-otp ]))

      expect # handles passwords from storage
      pwgen # generates randomized passwords
    ];

    env.PASSWORD_STORE_DIR = "$XDG_CONFIG_HOME/pass";
  };
}
