# hosts/macbook/default.nix -- standalone home-manager entry point for macOS
#
# Imports the shared modules/* files directly. Each module guards Linux-only
# options with optionalAttrs (!pkgs.stdenv.isDarwin) and provides Darwin-native
# programs.* config in the isDarwin branch.
#
# Activation:
#   # For the first run:
#   nix run nixpkgs#home-manager -- switch --flake .#mcunha --impure
#   
#   # Then all subsequent runsL
#   home-manager switch --flake .#mcunha --impure

{ config, pkgs, lib, ... }:

let
  # Machine-local overrides live outside the flake so they are never committed.
  # 
  # Requires: home-manager switch --flake .#mcunha --impure
  privateConfig = /Users/mcunha/.config/home-manager/local.nix;

  # Auto-discover all .nix files in a module subdirectory.
  # 
  # Modules default to disabled; each handles its own isDarwin guards.
  nixFilesIn = dir:
    lib.mapAttrsToList (name: _: dir + "/${name}") (lib.filterAttrs
      (name: type: type == "regular" && lib.hasSuffix ".nix" name)
      (builtins.readDir dir));
in {
  imports = nixFilesIn ../../modules/editors ++ nixFilesIn ../../modules/shell
    ++ nixFilesIn ../../modules/development
    ++ nixFilesIn ../../modules/networking ++ [
      ./modules.nix
    ] ++ lib.optional (builtins.pathExists privateConfig) privateConfig;

  home = {
    username = "mcunha";
    homeDirectory = "/Users/mcunha";
    stateVersion = "26.05";

    packages = with pkgs; [
      wget
      curl
      unzip
      gnumake

      # Nix tooling
      nil
      nixfmt
    ];

    sessionVariables.DOTFILES = toString ../..;
  };

  programs.home-manager.enable = true;

  xdg = {
    enable = true;
    configHome = "${config.home.homeDirectory}/.config";
    cacheHome = "${config.home.homeDirectory}/.cache";
    dataHome = "${config.home.homeDirectory}/.local/share";
  };
}
