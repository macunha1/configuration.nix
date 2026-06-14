# desktop/wm/awesome.nix -- https://awesomewm.org/
#
# Module for the Awesome Window Manager, the next generation framework for X.
# Supports async implementations using XCB and customization with Lua.
# Ref: https://xcb.freedesktop.org/

{
  config,
  options,
  lib,
  pkgs,
  ...
}:

with lib;
let
  # Some standalone evaluations pass plain nixpkgs.lib, so lib.my may be absent.
  # Import the generator directly in that case.
  inherit (lib.my or (import ../../../lib/generators.nix { inherit lib pkgs; }))
    generatedFileWarning
    ;

  luaJitEnabled = config.modules.development.lua.enable && config.modules.development.lua.jit.enable;

  lua = if luaJitEnabled then pkgs.luajit else pkgs.lua;

  luaPackages = if luaJitEnabled then pkgs.luajitPackages else pkgs.luaPackages;

  awesome = pkgs.awesome.override {
    gtk3Support = true;
    inherit lua;
  };

  lua-dbus-proxy = pkgs.my.lua-dbus-proxy.override {
    inherit lua luaPackages;
  };
in
{
  options.modules.desktop = {
    awesomewm.enable = mkOption {
      type = types.bool;
      default = false;
    };

    compton.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.awesomewm.enable {
    services = {
      compton.enable = config.modules.desktop.compton.enable;
      xserver = {
        displayManager.defaultSession = "none+awesome";
        windowManager.awesome = {
          enable = true;
          package = awesome;
          luaModules = [ lua-dbus-proxy ];
        };
      };
    };

    user.packages = with pkgs; [
      i3lock # screenlock.sh requires i3lock

      # Creates a custom AwesomeWM wrapper supporting "LUA_PATH" in startx,
      # i.e. Implements the equivalent of
      #      luaModules = [ lua-dbus-proxy ]; # in a non-DM world
      (writeScriptBin "awm" ''
        #!${stdenv.shell}
        ${generatedFileWarning { file = ./awesome.nix; }}
        exec ${awesome}/bin/awesome \
             --search "${lua-dbus-proxy.out}/share/lua/${lua.luaversion}" \
             "$@"
      '')
    ];

    home-manager.users.${config.user.name}.services.screen-locker = {
      inactiveInterval = 10;
      lockCmd = "screenlock.sh";
    };

    home.configFile."awesome" = {
      source = pkgs.fetchFromGitHub {
        owner = "macunha1";
        repo = "aweswm";

        rev = "fd9aed4a26aa421544f8059fced2254616584e26";
        sha256 = "07iwii65s0yzqq3a00df5yyk6wfqh1nljgsw633qr0m87aiq2bry";

        fetchSubmodules = true;
      };
    };

  };
}
