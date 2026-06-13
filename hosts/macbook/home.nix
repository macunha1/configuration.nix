# hosts/macbook/home.nix -- standalone home-manager entry point for macOS
#
# Imports the shared modules/shell/* and modules/editors/* files directly.
# Each module guards Linux-only options with optionalAttrs (!pkgs.stdenv.isDarwin)
# and provides Darwin-native programs.* config in the isDarwin branch.
#
# Activation:
#   nix run nixpkgs#home-manager -- switch --flake .#mcunha   # first time
#   home-manager switch --flake .#mcunha                      # after

{ config, pkgs, lib, ... }:

let
  # Machine-local overrides live outside the flake so they are never committed.
  # Requires: home-manager switch --flake .#mcunha --impure
  privateConfig = /Users/mcunha/.config/home-manager/local.nix;

  ## Auto-discover all .nix files in a module subdirectory.
  ## Modules default to disabled; each handles its own isDarwin guards.
  nixFilesIn = dir:
    lib.mapAttrsToList
      (name: _: dir + "/${name}")
      (lib.filterAttrs
        (name: type: type == "regular" && lib.hasSuffix ".nix" name)
        (builtins.readDir dir));
in
{
  imports =
    nixFilesIn ../../modules/editors
    ++ nixFilesIn ../../modules/shell
    ++ nixFilesIn ../../modules/development
    ++ nixFilesIn ../../modules/networking
    ++ lib.optional (builtins.pathExists privateConfig) privateConfig;

  ## Module feature flags — mirrors the pattern in hosts/*/modules.nix
  modules = {
    editors = {
      default = "vim";
      vim.enable = true;
      emacs.enable = true;
    };

    shell = {
      git = {
        enable = true;
        # user.email set in local.nix (gitignored) — see local.nix.example
      };
      zsh.enable    = true;
      tmux.enable   = true;
      fzf.enable    = true;
      direnv.enable = true;
      pass.enable   = true;
      gnupg.enable  = true;
    };

    development.node = {
      enable = true;
      bun.enable = true;
    };

    networking.terraform.enable = true;
  };

  home = {
    username = "mcunha";
    homeDirectory = "/Users/mcunha";
    stateVersion = "26.05";

    packages = with pkgs; [
      wget
      curl
      unzip
      gnumake

      ## Nix tooling
      nil
      nixfmt-classic
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
