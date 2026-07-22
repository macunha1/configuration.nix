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
  inherit (lib.my or (import ../../lib/generators.nix { inherit lib pkgs; }))
    shellExports
    ;

  inherit (lib.my or (import ../../lib/modules.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  passEnvVars = {
    PASSWORD_STORE_DIR = xdg.concrete.config "pass";
  };

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
    (platformPackages {
      inherit isDarwin;
      packages = passPackages;
    })

    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = passEnvVars;
      darwinTarget = "zsh";
    })
  ]);
}
