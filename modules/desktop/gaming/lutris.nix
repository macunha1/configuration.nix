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
