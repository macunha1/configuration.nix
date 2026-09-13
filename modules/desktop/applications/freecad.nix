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

let
  python3Packages = pkgs.python3Packages.overrideScope (
    _final: previous: {
      ifcopenshell = previous.ifcopenshell.overrideAttrs (previousAttrs: {
        postPatch = (previousAttrs.postPatch or "") + ''
          # Backport https://github.com/IfcOpenShell/IfcOpenShell/commit/34da3950e37d6d83effb7186f890e0e73ee9f683
          # together with the constructor it builds on. Boost 1.91 made its
          # optional converting constructor explicit.
          substituteInPlace src/ifcgeom/profile_helper.h \
            --replace-fail \
              $'\t\t\tboost::optional<double> radius;\n\t\t};' \
              $'\t\t\tboost::optional<double> radius;\n\n\t\t\tprofile_point(const std::array<double, 2>& p, const boost::optional<double>& r = boost::none)\n\t\t\t\t: xy(p), radius(r) {\n\t\t\t}\n\n\t\t\tprofile_point(const std::array<double, 2>& p, double r)\n\t\t\t\t: xy(p), radius(r) {\n\t\t\t}\n\t\t};'
        '';
      });
    }
  );
in
with lib;
{
  options.modules.desktop.applications.freecad = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.applications.freecad.enable {
    user.packages = [ (pkgs.freecad.override { inherit python3Packages; }) ];
  };
}
