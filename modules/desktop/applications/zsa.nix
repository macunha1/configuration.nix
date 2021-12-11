# applications/zsa.nix -- https://www.zsa.io/
#
# Wally CLI helps flashing the firmware updates generated through ZSA Keyboard
# configurator. ZSA is the company behind ErgoDox, Moonlander and Planck.
# Ref: https://configure.zsa.io/

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.desktop.applications.zsa = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.applications.zsa.enable {
    user.packages = [ pkgs.unstable.wally-cli ];

    hardware.keyboard.zsa.enable = true;

    user.extraGroups = [ "plugdev" ];
  };
}
