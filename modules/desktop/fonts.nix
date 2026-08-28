{
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:

with lib;

let
  sourceCodePro = import ../../lib/fonts/source-code-pro.nix { inherit pkgs; };

  fontPackages = [
    pkgs.powerline-fonts
    sourceCodePro.package
  ];
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
        fontconfig.defaultFonts.monospace = [ sourceCodePro.family ];
      };
    })

    (optionalAttrs isDarwin {
      home.packages = fontPackages;
      home.file = sourceCodePro.darwinHomeFiles;
    })
  ]);
}
