{ pkgs }:

let
  family = "Source Code Pro";
  package = pkgs.source-code-pro;

  files = [
    "SourceCodePro-Black.otf"
    "SourceCodePro-BlackIt.otf"
    "SourceCodePro-Bold.otf"
    "SourceCodePro-BoldIt.otf"
    "SourceCodePro-ExtraLight.otf"
    "SourceCodePro-ExtraLightIt.otf"
    "SourceCodePro-It.otf"
    "SourceCodePro-Light.otf"
    "SourceCodePro-LightIt.otf"
    "SourceCodePro-Medium.otf"
    "SourceCodePro-MediumIt.otf"
    "SourceCodePro-Regular.otf"
    "SourceCodePro-Semibold.otf"
    "SourceCodePro-SemiboldIt.otf"
  ];
in
{
  inherit family package;

  darwinHomeFiles = builtins.listToAttrs (
    map (file: {
      name = "Library/Fonts/${file}";
      value.source = "${package}/share/fonts/opentype/${file}";
    }) files
  );
}
