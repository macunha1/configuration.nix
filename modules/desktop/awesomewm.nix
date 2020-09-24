{ config, options, lib, pkgs, ... }:

with lib; {
  options.modules.desktop = {
    awesomewm.enable = mkOption {
      type = types.bool;
      default = false;
    };

    comptom.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.awesomewm.enable {
    my = {
      packages = with pkgs; [
        i3lock # screenlock.sh uses i3lock

        # Creates a custom AwesomeWM wrapper supporting "LUA_PATH" in startx,
        # i.e. Implements the equivalent of
        #      luaModules = [ pkgs.my.luaDbusProxy ]; # in a non-DM world
        (writeScriptBin "awm" ''
          #!${stdenv.shell}
          exec ${awesome}/bin/awesome \
               --search "${my.luaDbusProxy.out}/share/lua/${lua.luaversion}" \
               "$@"
        '')
      ];

      home = {
        services.screen-locker = {
          inactiveInterval = 10;
          lockCmd = "screenlock.sh";
        };

        xdg.configFile."awesome" = {
          source = pkgs.fetchFromGitHub {
            owner = "macunha1";
            repo = "awesomewm-configuration";

            rev = "d5eb1e76b55b92b27084401ece56723eeff9bcc8";
            sha256 = "0s4cissygjp4gn0sk23wr5q590qmlp05lka7ifpg6f0pdrvzh3k0";

            fetchSubmodules = true;
          };
        };
      };
    };

    nixpkgs.overlays = [
      (self: super:
        with super; {
          awesome = super.awesome.override {
            # luaPackages = super.luajitPackages;
            gtk3Support = true;
          };
        })
    ];

    services = {
      compton.enable = config.modules.desktop.comptom.enable;

      xserver = {
        enable = true;

        windowManager.awesome = {
          enable = true;
          luaModules = [ pkgs.my.luaDbusProxy ];
        };

        displayManager.lightdm.enable = true;
        desktopManager.xterm.enable = false;
      };
    };
  };
}
