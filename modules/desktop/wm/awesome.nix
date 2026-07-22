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

  awesomeLuaModules = optional config.modules.hardware.audio.enable (
    pkgs.my.lua-dbus-proxy.override {
      inherit lua luaPackages;
    }
  );

  awesomeLuaSearchArgs = concatMapStringsSep " \\\n             " (
    module: ''--search "${module.out}/share/lua/${lua.luaversion}"''
  ) awesomeLuaModules;
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
      picom.enable = config.modules.desktop.compton.enable;
      displayManager.defaultSession = "none+awesome";
      xserver = {
        windowManager.awesome = {
          enable = true;
          package = awesome;
          luaModules = awesomeLuaModules;
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
        ${if awesomeLuaSearchArgs == "" then ''
          exec ${awesome}/bin/awesome "$@"
        '' else ''
          exec ${awesome}/bin/awesome \
          ${awesomeLuaSearchArgs} \
          "$@"
        ''}
      '')
    ]
    ++ optionals config.modules.hardware.audio.enable [
      wireplumber # wpexec runs WirePlumber Lua API scripts from Awesome keybindings
    ];

    home-manager.users.${config.user.name}.services.screen-locker = {
      inactiveInterval = 10;
      lockCmd = "screenlock.sh";
    };

    home.configFile."awesome" = {
      source = pkgs.fetchFromGitHub {
        owner = "macunha1";
        repo = "aweswm";

        rev = "95719817bcb3a30d8fe9b91dd277110a3c6e7b2a";
        sha256 = "sha256-ig+/xkId+jZFfzMluuoUeerPDifJPiwAmXjsv8v1WNw=";

        fetchSubmodules = true;
      };
    };

  };
}
