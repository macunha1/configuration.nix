{ config, options, pkgs, lib, ... }:

# calibre.nix -- https://calibre-ebook.com/download
# Calibre open source e-books manager

with lib; {
  options.modules.desktop.applications.calibre = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.applications.calibre.enable {
    user.packages = [ pkgs.calibre ];
  };
}
