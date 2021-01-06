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
