# development/flutter.nix -- https://flutter.dev/
#
# React Native made right, develop a single (and useful) code base for both
# popular mobile platforms (as of this writing): iOS and Android.
#
# Flutter adds some capabilities on top of the original mobile app development
# in terms of annimations and fancy effects as well.
#
# Linux: user.packages + env = flutterEnvVars.
# Darwin: home.packages + home.sessionVariables = flutterEnvVars.

{
  config,
  options,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

with lib;

let
  flutterPackages = with pkgs; [
    flutter # framework + CLI (dart bundled)
    dart # explicit dart SDK for IDE tooling
  ];

  # Flutter path configuration — same values on both platforms.
  flutterEnvVars = {
    FLUTTER_ROOT = config.modules.development.flutter.path;
    # TODO: Install downloaded tools to bin (+patchelf)
    DART_SDK_PATH = "${config.modules.development.flutter.path}/bin/cache/dart-sdk";
  };
in
{
  options.modules.development.flutter = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    path = mkOption {
      type = with types; (either str path);
      default = "$XDG_DATA_HOME/flutter";
    };

    includeBinToPath = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.flutter.enable (mkMerge [

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = flutterPackages;
      env = flutterEnvVars;
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      home.packages = flutterPackages;
      home.sessionVariables = flutterEnvVars;
    })
  ]);
}
