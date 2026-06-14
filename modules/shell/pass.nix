# shell/pass.nix -- https://www.passwordstore.org/
#
# Simple CLI util that takes advantage of GNU Privacy Guards to encrypt files
# and store secrets locally. In-a-nutshell: a wrapper for 'gpg' with directory
# management for the encrypted content.
#
# Linux: user.packages + env.PASSWORD_STORE_DIR.
# Darwin: home.packages + modules.shell.zsh.env.

{
  config,
  options,
  pkgs,
  lib,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

with lib;

let
  passPackages = with pkgs; [
    (pass.withExtensions (exts: [
      # OTP support (2FA codes in pass)
      exts.pass-otp
    ]))

    expect # automates interactive password prompts
    pwgen # generates randomized, memorable passwords
  ];
in
{
  options.modules.shell.pass = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.pass.enable (mkMerge [

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = passPackages;
      env.PASSWORD_STORE_DIR = "$XDG_CONFIG_HOME/pass";
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      home.packages = passPackages;

      # home.sessionVariables does not reliably reach interactive shell apps on
      # macOS, so write the variable into zsh env init instead.
      modules.shell.zsh.env = ''
        export PASSWORD_STORE_DIR="${config.xdg.configHome}/pass"
      '';
    })
  ]);
}
