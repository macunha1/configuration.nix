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
  };

  inputs = {
    # Core dependencies.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixlib.url = "github:nix-community/nixpkgs.lib";

    latest.url = "github:nixos/nixpkgs/nixos-unstable";
    blank.url = "github:divnix/blank";

    # NixOS Hardware contain hardware-specific configurations (e.g. MacOS Wi-Fi
    # drivers, proprietary notebook battery Kernel modules, etc) that helps
    # speeding up the NixOS setup on some machines.
    #
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";

    deploy.url = "github:serokell/deploy-rs";
    deploy.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixlib";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixlib";

    # flake-compat = {
    #   url = "github:edolstra/flake-compat";
    #   flake = false;
    # };

    # Extras
    emacs-overlay.url = "github:nix-community/emacs-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixlib,
      home-manager,
      flake-parts,
      ...
    }@inputs:

    let
      inherit (lib) attrValues;
      inherit (lib.my) mapModules mapModulesRec mapHosts;

      hostSystems = {
        nixbox = "x86_64-linux";
        nixosmos = "x86_64-linux";
        orbit = "aarch64-linux";
        macbook = "aarch64-darwin";
      };

      defaultLinuxSystem = "x86_64-linux";

      systems = lib.unique (attrValues hostSystems);

      nixpkgsConfig = { };

      # Flake package exports and standalone Home Manager receive pkgs before
      # module config exists, so keep this narrow and package-driven.
      flakePackageNixpkgsConfig = {
        allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "aspell-dict-en-science"
            "claude-code"
            "terraform-bin"
          ];
      };

      tests = import ./tests;

      mkConfiguredPkgs =
        system: config: extraOverlays:
        import nixpkgs {
          inherit system;
          inherit config;
          overlays = extraOverlays ++ (attrValues self.overlays);
        };

      linuxPkgs = mkConfiguredPkgs defaultLinuxSystem flakePackageNixpkgsConfig [
        inputs.emacs-overlay.overlay
      ];

      darwinPkgs = mkConfiguredPkgs hostSystems.macbook flakePackageNixpkgsConfig [
        inputs.emacs-overlay.overlay
      ];

      lib = nixpkgs.lib.extend (
        self: super: {
          # Use nice convenient functions developed by @hlissner
          # Ref: https://github.com/hlissner/dotfiles/tree/804011f53826c226cbf7e0acd8002087a223051d/lib
          my = import ./lib {
            inherit inputs;
            pkgs = linuxPkgs;
            lib = self;
          };
        }
      );
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      inherit systems;

      perSystem =
        { system, ... }:
        let
          pkgs = mkConfiguredPkgs system flakePackageNixpkgsConfig [ inputs.emacs-overlay.overlay ];

          activate = pkgs.writeShellApplication {
            name = "activate";
            runtimeInputs = [ pkgs.nix ];
            text = ''
              set -eu

              flake="''${FLAKE:-$PWD}"
              system_name="$(uname -s)"

              case "$system_name" in
                Darwin)
                  home_config="''${HOME_CONFIG:-''${CONFIG_USER:-''${USER:-mcunha}}}"
                  exec nix run --no-warn-dirty nixpkgs#home-manager -- \
                    switch --flake "$flake#$home_config" --impure
                  ;;
                Linux)
                  nixos_host="''${NIXOS_HOST:-''${HOST:-$(hostname)}}"
                  exec nixos-rebuild --flake "$flake#$nixos_host" --fast switch
                  ;;
                *)
                  printf 'Unsupported OS: %s\n' "$system_name" >&2
                  exit 1
                  ;;
              esac
            '';
          };
        in
        {
          apps.activate = {
            type = "app";
            program = "${activate}/bin/activate";
            meta.description = "Activate the local NixOS or standalone Home Manager configuration";
          };
          packages = mapModules ./packages (p: pkgs.callPackage p { });
          devShells.default = import ./shell.nix { inherit pkgs; };
        };

      flake = {
        lib = lib.my;

        overlays = {
          default = final: prev: {
            my = self.packages.${prev.stdenv.hostPlatform.system or defaultLinuxSystem};
          };
        }
        // mapModules ./overlays import;

        nixosModules = {
          dotfiles = import ./.;
        }
        // mapModulesRec ./modules import;

        nixosConfigurations = mapHosts ./hosts {
          system = defaultLinuxSystem;
          ignoredHosts = [ "macbook" ];
          hostSystemOverrides = builtins.removeAttrs hostSystems [ "macbook" ];
          inherit nixpkgsConfig;
          nixpkgsOverlays = [
            self.overlays.default
            inputs.emacs-overlay.overlay
          ];
        };

        ## macOS standalone home-manager configurations
        #
        # # First-time setup:
        # nix run nixpkgs#home-manager -- switch --flake .#mcunha --impure
        #
        # # Subsequent runs:
        # home-manager switch --flake .#mcunha --impure
        homeConfigurations."mcunha" = home-manager.lib.homeManagerConfiguration {
          pkgs = darwinPkgs;
          modules = [ ./hosts/macbook ];
          extraSpecialArgs = {
            inherit inputs;
            isDarwin = true;
          };
        };
      };
    };
}
