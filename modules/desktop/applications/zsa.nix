# applications/uhk-agent.nix -- https://www.zsa.io/
#

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
