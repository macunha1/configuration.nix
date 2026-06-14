# development/android.nix -- https://www.android.com/
#
# ADB and Fastboot tooling.
#
# This module is Linux-only: it uses udev rules (services.udev) and the adbusers
# group (users.groups), neither of which exists on macOS. iOS/Android development
# on macOS is better handled via Android Studio directly.

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
  androidTools = pkgs.android-tools;

  # Minimal SDK-shaped directory for tools that expect $ANDROID_SDK_ROOT/platform-tools/adb.
  androidAdbSdk = pkgs.runCommand "android-adb-sdk-${androidTools.version}" { } ''
    mkdir -p "$out/platform-tools"
    ln -s ${androidTools}/bin/adb "$out/platform-tools/adb"
    ln -s ${androidTools}/bin/fastboot "$out/platform-tools/fastboot"
  '';
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

  # Linux-only: udev rules and adbusers are not available on macOS.
  config = mkIf config.modules.development.android.enable (
    optionalAttrs (!isDarwin) (mkMerge [
      {
        # Copied from programs.adb to extend its capability with a custom pkg
        # Ref: github.com/NixOS/nixpkgs/blob/master/nixos/modules/programs/adb.nix
        services.udev.packages = with pkgs; [
          android-udev-rules
          usbutils
        ];
        users.groups.adbusers = { }; # forces group creation

        user = {
          extraGroups = [ "adbusers" ];

          packages = [ androidTools ];
        };

        env.ANDROID_SDK_ROOT = "${androidAdbSdk}";
        env.ANDROID_USER_HOME = config.modules.development.android.path;
      }

      (mkIf config.modules.development.android.includeBinToPath {
        env.PATH = [ "$ANDROID_SDK_ROOT/platform-tools" ];
      })
    ])
  );
}
