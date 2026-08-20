{
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:

with lib;

let
  fontPackages = with pkgs; [
    powerline-fonts
    source-code-pro
  ];

  sourceCodeProFontFiles = [
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

  sourceCodeProHomeFontLinks = builtins.listToAttrs (
    map (fontFile: {
      name = "Library/Fonts/${fontFile}";
      value.source = "${pkgs.source-code-pro}/share/fonts/opentype/${fontFile}";
    }) sourceCodeProFontFiles
  );
in
{
  options.modules.desktop.fonts = {
    enable = mkOption {
      type = types.bool;
      default = config.modules.desktop.enable or false;
    };
  };

  config = mkIf config.modules.desktop.fonts.enable (mkMerge [
    (optionalAttrs (!isDarwin) {
      fonts = {
        fontDir.enable = true;
        enableGhostscriptFonts = true;

        packages = fontPackages;
        fontconfig.defaultFonts.monospace = [ "Source Code Pro" ];
      };
    })

    (optionalAttrs isDarwin {
      home.packages = fontPackages;
      home.file = sourceCodeProHomeFontLinks;
    })
  ]);
}
