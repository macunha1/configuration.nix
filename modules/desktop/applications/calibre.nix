# applications/calibre.nix -- https://calibre-ebook.com/download
#
# Calibre open source e-books manager. Supports conversion among formats (EPUB,
# AZW3, MOBI, etc) and books library (sync between PC and e-reader)

{ config, options, pkgs, lib, ... }:

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
