# development/android.nix -- https://www.android.com/
#
# Android SDK, emulator, and ADB tooling.
#
# This module is Linux-only: it uses udev rules (services.udev), the adbusers
# group (users.groups), and KVM-backed emulation — none of which exist on macOS.
# iOS/Android development on macOS is better handled via Android Studio directly.

{ config, options, lib, pkgs, isDarwin ? pkgs.stdenv.isDarwin, ... }:

with lib;

let
  ## Android SDK composition — platform and build tool versions pinned here.
  androidPackages = pkgs.androidenv.composeAndroidPackages {
    platformVersions     = [ "28" "29" "30" ];
    platformToolsVersion = "34.0.1";
    toolsVersion         = "26.1.1";
    buildToolsVersions   = [ "33.0.2" ];
    abiVersions          = [ "x86" "x86_64" ];

    includeEmulator = true;
    emulatorVersion = "33.1.6";
  };
in
{
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

  ## Linux-only: udev rules and KVM emulation are not available on macOS.
  config = mkIf config.modules.development.android.enable (
    optionalAttrs (!isDarwin) (mkMerge [
      {
        # Copied from programs.adb to extend its capability with a custom pkg
        # Ref: github.com/NixOS/nixpkgs/blob/master/nixos/modules/programs/adb.nix
        services.udev.packages = with pkgs; [ android-udev-rules usbutils ];
        users.groups.adbusers = { }; # forces group creation

        user = {
          extraGroups = [ "adbusers" ];

          packages = with pkgs; [
            androidPackages.androidsdk

            # Version-pinned emulator wrapper to avoid path/version conflicts
            (writeScriptBin "amulator" ''
              #!${stdenv.shell}
              exec ${androidPackages.emulator}/libexec/android-sdk/emulator/emulator "$@"
            '')
          ];
        };

        env.ANDROID_SDK_ROOT      = "${config.modules.development.android.path}/sdk";
        env.ANDROID_AVD_HOME      = "${config.modules.development.android.path}/avd";
        env.ANDROID_EMULATOR_HOME = "${config.modules.development.android.path}/emulator";
      }

      (mkIf config.modules.development.android.includeBinToPath {
        env.PATH = [ "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin" ];
      })
    ])
  );
}
