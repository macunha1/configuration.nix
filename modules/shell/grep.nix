{
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
  inherit (lib.my or (import ../../lib/modules/utils.nix { inherit lib; })) platformPackages;
in
{
  options.modules.shell.grep = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.shell.grep.enable (platformPackages {
    inherit isDarwin;
    packages = [
      pkgs.ast-grep
      pkgs.ripgrep
    ];
  });
}
