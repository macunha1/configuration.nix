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
    let
      # `readDir` gives us every entry, including directories and helper files
      # we do not want to import.
      entries = builtins.readDir dir;

      # Keep only plain `.nix` files. Subdirectories are handled elsewhere, and
      # non-Nix files should stay invisible to module discovery.
      nixEntries = lib.filterAttrs
        (name: type: type == "regular" && lib.hasSuffix ".nix" name)
        entries;
    in
      # Turn the filtered set back into a list of import paths.
      lib.mapAttrsToList (name: _: dir + "/${name}") nixEntries;
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
      nixfmt
      nixfmt-tree
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
