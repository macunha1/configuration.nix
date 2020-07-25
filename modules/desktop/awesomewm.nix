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
    my.packages = with pkgs; [
      # TODO: Include installation for Spotify CLI
      rofi
    ];

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

    # link recursively so other modules can link files in their folders
    # my.home.xdg.configFile = {
    #   "awesome" = {  }; # Fetch from Git
    # };
  };
}
