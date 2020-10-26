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

            rev = "7d69519f36876422b18f4995eed20c43e6d270f4";
            sha256 = "1b9jcfzrdb11z4myjcv2s7j8yyrn9kxid1kn1syc6cz7zqxksshx";

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
