{ config, lib, pkgs, ... }:
with lib; {
  options.modules.desktop.browsers = {
    default = mkOption {
      type = with types; nullOr str;
      default = null;
    };
  };

  config = mkIf (config.modules.desktop.browsers.default != null) {
    env.BROWSER = config.modules.desktop.browsers.default;
  };
}
