# applications/freecad.nix -- https://www.freecad.org/
#
# FreeCAD is an open-source parametric 3D modeler for product design,
# mechanical engineering, and architecture.

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
{
  options.modules.desktop.applications.freecad = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.applications.freecad.enable {
    user.packages = [ pkgs.freecad ];
  };
}
