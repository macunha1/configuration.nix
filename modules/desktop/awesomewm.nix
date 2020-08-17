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
      packages = with pkgs;
        [
          i3lock # screenlock.sh uses i3lock
        ];

      home = {
        services.screen-locker = {
          inactiveInterval = 10;
          lockCmd = "screenlock.sh";
        };

        # TODO: Include AwesomeWM repository clone inside config
        # Once fetchGit with fetchTree reaches a stable version release.
        # Ref: https://github.com/NixOS/nix/pull/3166
        # xdg.configFile."awesome" = {
        #   source = builtins.fetchGit {
        #     url = "ssh://git@gitlab.com/macunha/awesome-configuration.git";
        #     submodules = true;
        #   };
        # };
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

        displayManager.startx.enable = true;
        desktopManager.xterm.enable = false;
      };
    };
  };
}
