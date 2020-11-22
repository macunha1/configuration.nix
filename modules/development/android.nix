# modules/development/android.nix --- https://www.android.com/

{ config, options, lib, pkgs, ... }:

with lib;
let
  androidPackages = pkgs.unstable.androidenv.composeAndroidPackages {
    platformVersions = [ "29" ];
    platformToolsVersion = "29.0.6";
    buildToolsVersions = [ "29.0.3" ];
    abiVersions = [ "x86" "x86_64" ];

    includeEmulator = true;
    emulatorVersion = "30.0.3";
  };
in {
  options.modules.development.android = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    path = mkOption {
      type = types.path;
      default = "$XDG_DATA_HOME/android";
    };

    includeBinToPath = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.android.enable {
    # NOTE: Adb installs pkgs.androidenv.androidPkgs_9_0.platform-tools
    programs.adb.enable = true;

    # error: You MUST accept the Android SDK License Agreement
    # https://developer.android.com/studio/terms
    nixpkgs.config.android_sdk.accept_license = true;

    my = mkMerge [
      {
        user.extraGroups = [ "adbusers" ];
        packages = with pkgs; [
          androidPackages.androidsdk

          # Creates a executable script ensuring the version, mainly to avoid conflicts
          (writeScriptBin "amulator" ''
            #!${stdenv.shell}
            exec ${androidPackages.emulator}/libexec/android-sdk/emulator/emulator "$@"
          '')
        ];

        env.ANDROID_SDK_ROOT = "${config.modules.development.android.path}/sdk";
        env.ANDROID_AVD_HOME = "${config.modules.development.android.path}/avd";
        env.ANDROID_EMULATOR_HOME =
          "${config.modules.development.android.path}/emulator";
      }

      (mkIf config.modules.development.android.includeBinToPath {
        env.PATH = [ "$ANDROID_SDK_ROOT/tools/bin" ];
      })
    ];
  };
}
