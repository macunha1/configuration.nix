# desktop/wm/awesome.nix -- https://awesomewm.org/
#
# Module for the Awesome Window Manager, the next generation framework for X.
# Supports async implementations using XCB and customization with Lua.
# Ref: https://xcb.freedesktop.org/

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  # Some standalone evaluations pass plain nixpkgs.lib, so lib.my may be absent.
  # Import the generator directly in that case.
  inherit (lib.my or (import ../../../lib/generators.nix { inherit lib pkgs; }))
    generatedFileWarning
    ;

  # Awesome and its screenlock plugin share one Lua ABI. The plugin installs
  # its module for Lua 5.1, so keep the window manager on LuaJIT regardless of
  # which interpreter the development module exposes to interactive shells.
  awesomeLua = pkgs.luajit;

  awesomeLuaPackages = pkgs.luajitPackages;

  awesomePackage = pkgs.awesome.override { lua5_2_compat = awesomeLua; };

  aweswm = pkgs.fetchFromGitHub {
    owner = "macunha1";
    repo = "aweswm";
    rev = "a555d1ba37b8a3cc31e3d3065c6a2b1ff5bf3498";
    hash = "sha256-/Voi9ksj+RD1GkoaL3XUe2NZU7sGMjr2k4BO1w5Lkk4=";
    fetchSubmodules = true;
  };

  awesomeLuaModules = optional config.modules.hardware.audio.enable (
    pkgs.my.lua-dbus-proxy.override {
      lua = awesomeLua;
      luaPackages = awesomeLuaPackages;
    }
  );

  awesomeLuaSearchArgs = concatMapStringsSep " \\\n             " (
    module: ''--search "${module.out}/share/lua/${awesomeLua.luaversion}"''
  ) ([ config.services.awesomewm-screenlock.package ] ++ awesomeLuaModules);

in
{
  imports = [ inputs.awesomewm-screenlock-plugin.nixosModules.default ];

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

  config = mkMerge [
    {
      assertions = [
        {
          assertion = !config.modules.desktop.awesomewm.enable || config.modules.desktop.enable;
          message = "modules.desktop.awesomewm requires modules.desktop.enable";
        }
      ];
    }

    (mkIf config.modules.desktop.awesomewm.enable {
      services = {
        awesomewm-screenlock.enable = true;
        picom.enable = config.modules.desktop.compton.enable;
        displayManager.defaultSession = "none+awesome";
        xserver = {
          windowManager.awesome = {
            enable = true;
            package = awesomePackage;
            luaModules = awesomeLuaModules;
          };
        };
      };

      user.packages =
        with pkgs;
        [
          # Creates a custom AwesomeWM wrapper supporting "LUA_PATH" in startx,
          # i.e. Implements the equivalent of
          #      luaModules = [ lua-dbus-proxy ]; # in a non-DM world
          (writeScriptBin "awm" ''
            #!${stdenv.shell}
            ${generatedFileWarning { file = ./awesome.nix; }}
            ${
              if awesomeLuaSearchArgs == "" then
                ''
                  exec ${awesomePackage}/bin/awesome "$@"
                ''
              else
                ''
                  exec ${awesomePackage}/bin/awesome \
                  ${awesomeLuaSearchArgs} \
                  "$@"
                ''
            }
          '')
        ]
        ++ optionals config.modules.hardware.audio.enable [
          wireplumber # wpexec runs WirePlumber Lua API scripts from Awesome keybindings
        ];

      home-manager.users.${config.user.name} = {
        services.screen-locker = {
          enable = true;
          inactiveInterval = 10;
          lockCmd = "${awesomePackage}/bin/awesome-client 'require(\"awesomewm_screenlock\")():lock()'";
        };

        home.file.".local/share/awesomewm-screenlock-plugin".source =
          config.services.awesomewm-screenlock.package;
      };

      home.configFile."awesome".source = aweswm;

    })
  ];
}
