# hosts/macbook/default.nix -- standalone home-manager entry point for macOS
#
# Imports the shared modules/* files directly. Each module guards Linux-only
# options with optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) and provides Darwin-native
# programs.* config in the isDarwin branch.
#
# Activation:
#   # For the first run:
#   nix run nixpkgs#home-manager -- switch --flake .#mcunha --impure
#
#   # Then all subsequent runsL
#   home-manager switch --flake .#mcunha --impure

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Machine-local overrides live outside the flake so they are never committed.
  #
  # Requires: home-manager switch --flake .#mcunha --impure
  privateConfig = /Users/mcunha/.config/home-manager/local.nix;

  # Auto-discover all .nix files in a module subdirectory.
  #
  # Modules default to disabled; each handles its own isDarwin guards.
  nixFilesIn =
    dir:
    let
      # `readDir` gives us every entry, including directories and helper files
      # we do not want to import.
      entries = builtins.readDir dir;

      # Keep only plain `.nix` files. Subdirectories are handled elsewhere, and
      # non-Nix files should stay invisible to module discovery.
      nixEntries = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) entries;
    in
    # Turn the filtered set back into a list of import paths.
    lib.mapAttrsToList (name: _: dir + "/${name}") nixEntries;
in
{
  imports =
    nixFilesIn ../../modules/agents/code
    ++ nixFilesIn ../../modules/agents/mcp
    ++ nixFilesIn ../../modules/agents/plugins
    ++ nixFilesIn ../../modules/editors
    ++ nixFilesIn ../../modules/shell
    ++ nixFilesIn ../../modules/development
    ++ nixFilesIn ../../modules/networking
    ++ [
      ../../modules/desktop/fonts.nix
      ./modules.nix
    ]
    ++ lib.optional (builtins.pathExists privateConfig) privateConfig;

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

  # Home Manager still emits `nix profile install`, which Nix 2.34 warns is a
  # deprecated alias for `nix profile add`.
  home.activation.installPackages = lib.mkForce (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      function nixReplaceProfile() {
        local oldNix="$(command -v nix)"

        nixProfileRemove 'home-manager-path'

        run $oldNix profile add $1
      }

      if [[ -e ${config.home.profileDirectory}/manifest.json ]] ; then
        INSTALL_CMD="nix profile add"
        INSTALL_CMD_ACTUAL="nixReplaceProfile"
        LIST_CMD="nix profile list"
        REMOVE_CMD_SYNTAX='nix profile remove {number | store path}'
      else
        INSTALL_CMD="nix-env -i"
        INSTALL_CMD_ACTUAL="run nix-env -i"
        LIST_CMD="nix-env -q"
        REMOVE_CMD_SYNTAX='nix-env -e {package name}'
      fi

      if ! $INSTALL_CMD_ACTUAL ${config.home.path} ; then
        echo
        _iError $'Oops, Nix failed to install your new Home Manager profile!\n\nPerhaps there is a conflict with a package that was installed using\n"%s"? Try running\n\n    %s\n\nand if there is a conflicting package you can remove it with\n\n    %s\n\nThen try activating your Home Manager configuration again.' "$INSTALL_CMD" "$LIST_CMD" "$REMOVE_CMD_SYNTAX"
        exit 1
      fi
      unset -f nixReplaceProfile
      unset INSTALL_CMD INSTALL_CMD_ACTUAL LIST_CMD REMOVE_CMD_SYNTAX
    ''
  );
}
