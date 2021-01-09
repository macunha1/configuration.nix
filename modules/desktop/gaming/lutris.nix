# desktop/gaming/lutris.nix -- https://lutris.net/
#
# Take your Wine configurations to the next level using community settings
# adjusted for each game, including rating and validated shared settings.

{ options, config, lib, pkgs, ... }:

with lib; {
  options.modules.desktop.gaming.lutris = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.gaming.lutris.enable {
    user.packages = with pkgs; [ vulkan-tools vulkan-headers lutris ];
  };
}
