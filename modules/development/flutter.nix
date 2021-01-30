# development/flutter.nix -- https://flutter.dev/
#
# React Native made right, develop a single (and useful) code base for both
# popular mobile platforms (as of this writing): iOS and Android.
#
# Flutter adds some capabilities on top of the original mobile app development
# in terms of annimations and fancy effects as well.

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.development.flutter = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    path = mkOption {
      type = with types; (either str path);
      default = "$XDG_DATA_HOME/flutter";
    };

    # TODO: Install downloaded tools to bin (+patchelf)
    includeBinToPath = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.flutter.enable {
    user.packages = with pkgs; [ pkgs.flutter pkgs.dart ];

    env.FLUTTER_ROOT = config.modules.development.flutter.path;
    env.DART_SDK_PATH =
      "${config.modules.development.flutter.path}/bin/cache/dart-sdk";
  };
}
