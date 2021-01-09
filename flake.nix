# flake.nix -- Starting point for the snowball
#
# Further reading on Nix Flakes:
# Ref: https://nixos.wiki/wiki/Flakes
# Ref: https://github.com/nrdxp/nixflk#resources
#
# Implementation references:
#  + https://github.com/hlissner/dotfiles
#  + https://github.com/nrdxp/nixflk

{
  description = "Pile many flakes and you can have a beautiful snowman.";

  inputs = {
    # Core dependencies.
    # Track two channels (even though they're similar here) to allow granular
    # configurations based on each use case. Change as you wish.
    nixpkgs.url = "nixpkgs/master";
    nixpkgs-unstable.url = "nixpkgs/master";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Extras
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, ... }:
    let
      inherit (lib) attrValues;
      inherit (lib.my) mapModules mapModulesRec mapHosts;

      # Good luck trying to use Darwin or Windows. Modules are referring NixOS
      # configurations that made this transition hard.
      system = "x86_64-linux";

      mkPkgs = pkgs: extraOverlays:
        import pkgs {
          inherit system;
          config.allowUnfree = true; # necessary evil

          # error: You MUST accept the Android SDK License Agreement.
          # https://developer.android.com/studio/terms
          #
          # Therefore, if you do enable the Android module you're agreeing with
          # the terms
          config.android_sdk.accept_license = true;

          overlays = extraOverlays ++ (attrValues self.overlays);
        };

      pkgs = mkPkgs nixpkgs [ self.overlay ];
      uPkgs = mkPkgs nixpkgs-unstable [ ];

      lib = nixpkgs.lib.extend (self: super: {
        # Use nice convenient functions developed by @hlissner
        # Ref: https://github.com/hlissner/dotfiles/tree/804011f53826c226cbf7e0acd8002087a223051d/lib
        my = import ./lib {
          inherit pkgs inputs;
          lib = self;
        };
      });
    in {
      lib = lib.my;

      overlay = final: prev: {
        unstable = uPkgs;
        my = self.packages."${system}";
      };

      overlays = mapModules ./overlays import;

      packages."${system}" = mapModules ./packages (p: pkgs.callPackage p { });

      nixosModules = {
        dotfiles = import ./.;
      } // mapModulesRec ./modules import;

      nixosConfigurations = mapHosts ./hosts { inherit system; };

      devShell."${system}" = import ./shell.nix { inherit pkgs; };
    };
}
