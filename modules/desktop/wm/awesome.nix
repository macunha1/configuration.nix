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

  luaJitEnabled = config.modules.development.lua.enable && config.modules.development.lua.jit.enable;

  lua = if luaJitEnabled then pkgs.luajit else pkgs.lua;

  luaPackages = if luaJitEnabled then pkgs.luajitPackages else pkgs.luaPackages;

  aweswm = pkgs.fetchFromGitHub {
    owner = "macunha1";
    repo = "aweswm";
    rev = "51b19d8c4802cde4d5a3891ea2afbfd7bb20b2d4";
    hash = "sha256-hE2ssU6/WoBP3Qm5gGlne9CH2LfpOxPGWL4Qc1ecTKM=";
    fetchSubmodules = true;
  };

  awesomewmScreenlockPlugin = inputs.awesomewm-screenlock-plugin.packages.${pkgs.system}.default;

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
    security.pam.services.xlock.enable = true;

    services = {
      picom.enable = config.modules.desktop.compton.enable;
      displayManager.defaultSession = "none+awesome";
      xserver = {
        windowManager.awesome = {
          enable = true;
          package = pkgs.awesome.override { inherit lua; };
          luaModules = awesomeLuaModules;
        };
      };
    };

    user.packages = with pkgs; [
      awesomewmScreenlockPlugin
      # Creates a custom AwesomeWM wrapper supporting "LUA_PATH" in startx,
      # i.e. Implements the equivalent of
      #      luaModules = [ lua-dbus-proxy ]; # in a non-DM world
      (writeScriptBin "awm" ''
        #!${stdenv.shell}
        ${generatedFileWarning { file = ./awesome.nix; }}
        ${if awesomeLuaSearchArgs == "" then ''
          exec ${pkgs.awesome.override { inherit lua; }}/bin/awesome "$@"
        '' else ''
          exec ${pkgs.awesome.override { inherit lua; }}/bin/awesome \
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
      lockCmd = "${pkgs.awesome.override { inherit lua; }}/bin/awesome-client 'require(\"awesomewm_screenlock\")():lock()'";
    };

    home.configFile."awesome".source = aweswm;

  };
}
