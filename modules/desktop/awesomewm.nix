{ config, options, lib, pkgs, ... }:

with lib;
{
  imports = [
    ./common.nix
  ];

  options.modules.desktop.awesomewm = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.awesomewm.enable {
    my = {
      packages = with pkgs; [
        i3lock # screenlock.sh uses i3lock
        scrot  # Lightweight screenshooter

        feh  # Simple image viewer
        rofi # TUI all the things
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
      (
        self: super: with super; {
          awesome = super.awesome.override {
            luaPackages = super.luajitPackages;
          };
        })
    ];

    services.compton.enable = true;

    services.xserver = {
      enable = true;
      layout = "us";
      xkbVariant = "intl";

      windowManager.awesome.enable = true;

      displayManager = {
        startx.enable = true;
        defaultSession = "none+awesome";
      };

      desktopManager = {
        xterm.enable = false;
      };
    };
  };
}
