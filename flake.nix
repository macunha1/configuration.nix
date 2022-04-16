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

  nixConfig = {
    extra-experimental-features = "nix-command flakes";
    extra-substituters =
      "https://nrdxp.cachix.org https://nix-community.cachix.org";
    extra-trusted-public-keys =
      "nrdxp.cachix.org-1:Fc5PSqY2Jm1TrWfm88l6cvGWwz3s93c6IOifQWnhNW4= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
  };

  inputs = {
    # Core dependencies.
    # Track two channels (even though they're similar here) to allow granular
    # configurations based on each use case. Change as you wish.

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/master";

    nixlib.url = "github:nix-community/nixpkgs.lib";

    latest.url = "github:nixos/nixpkgs/nixos-unstable";
    blank.url = "github:divnix/blank";

    # NixOS Hardware contain hardware-specific configurations (e.g. MacOS Wi-Fi
    # drivers, proprietary notebook battery Kernel modules, etc) that helps
    # speeding up the NixOS setup on some machines.
    #
    # nixos-hardware.url = "github:nixos/nixos-hardware";

    deploy.url = "github:serokell/deploy-rs";
    deploy.inputs.nixpkgs.follows = "nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixlib";

    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";

    # flake-compat = {
    #   url = "github:edolstra/flake-compat";
    #   flake = false;
    # };

    # Extras
    emacs-overlay.url = "github:nix-community/emacs-overlay";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixlib, home-manager
    , flake-utils-plus, ... }@inputs:

    let
      inherit (lib) attrValues;
      inherit (lib.my) mapModules mapModulesRec mapHosts;

      # Good luck trying to use Darwin or Windows. Modules are referring NixOS
      # configurations that made this transition hard.
      system = "x86_64-linux";

      tests = import ./tests;

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
