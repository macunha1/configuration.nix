# development/android.nix -- https://www.android.com/

{ config, options, lib, pkgs, ... }:

with lib;
let
  androidPackages = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "28" "29" "30" ];
    platformToolsVersion = "34.0.1";
    toolsVersion = "26.1.1";
    buildToolsVersions = [ "33.0.2" ];
    abiVersions = [ "x86" "x86_64" ];

    includeEmulator = true;
    emulatorVersion = "33.1.6";
  };
in {
  options.modules.development.android = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    path = mkOption {
      type = with types; (either str path);
      default = "$XDG_DATA_HOME/android";
    };

    includeBinToPath = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.android.enable (mkMerge [
    {
      # Copied from the programs.adb to extend its capability with a custom pkg
      # Ref: github.com/NixOS/nixpkgs/blob/master/nixos/modules/programs/adb.nix
      services.udev.packages = with pkgs; [ android-udev-rules usbutils ];
      users.groups.adbusers = { }; # forces group creation

      user = {
        extraGroups = [ "adbusers" ];

        packages = with pkgs; [
          androidPackages.androidsdk

          # Creates a executable script ensuring the version, mainly to avoid conflicts
          (writeScriptBin "amulator" ''
            #!${stdenv.shell}
            exec ${androidPackages.emulator}/libexec/android-sdk/emulator/emulator "$@"
          '')
        ];
      };

      env.ANDROID_SDK_ROOT = "${config.modules.development.android.path}/sdk";
      env.ANDROID_AVD_HOME = "${config.modules.development.android.path}/avd";
      env.ANDROID_EMULATOR_HOME =
        "${config.modules.development.android.path}/emulator";
    }

    (mkIf config.modules.development.android.includeBinToPath {
      env.PATH = [ "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin" ];
    })
  ]);
}
