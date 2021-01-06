# modules/development/flutter.nix --- https://flutter.dev/

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
    user.packages = with pkgs; [ unstable.flutterPackages.dev unstable.dart ];

    env.FLUTTER_ROOT = config.modules.development.flutter.path;
    env.DART_SDK_PATH =
      "${config.modules.development.flutter.path}/bin/cache/dart-sdk";
  };
}
