{ inputs, config, lib, pkgs, ... }:

with lib;
with lib.my;
with inputs; {
  imports = [
    # home-manager to manage the dotfiles under $HOME. Mostly using XDG base
    # dir spec for configurations
    home-manager.nixosModules.home-manager
  ] ++ (mapModulesRec' (toString ./modules) import);

  ## Base Flake configuration
  # Mainly to make 'nix flake' available in the terminal for installation

  environment.variables = {
    DOTFILES = dotFilesDir;
    # Configure nix and nixpkgs
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  nix = {
    # Enable Flake experimental features
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";

    nixPath = (mapAttrsToList (n: v: "${n}=${v}") inputs) ++ [
      "nixpkgs-overlays=${dotFilesDir}/overlays"
      "dotfiles=${dotFilesDir}"
    ];

    registry = {
      nixos.flake = nixpkgs;
      nixpkgs.flake = nixpkgs-unstable;
    };

    settings = {
      sandbox = true;

      substituters = [ "https://nix-community.cachix.org" ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  ## Global defaults
  # Enables 'nix flake check' for hosts when there's no fileSystem config.
  fileSystems."/".device = mkDefault "/dev/disk/by-label/nixos";

  boot.loader = {
    efi.canTouchEfiVariables = mkDefault true;
    systemd-boot.configurationLimit = 10;
    systemd-boot.enable = mkDefault true;
  };

  environment.systemPackages = with pkgs; [
    # Nix basics
    cached-nix-shell
    patchelf
    nix-prefetch

    # Linux basic utils
    coreutils
    git
    vim
    gnumake
    unzip
    inetutils # telnet, hostname, ping and etc
    bind # nslookup, dig
  ];

  # This value determines the NixOS release with which your system is going to
  # be compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.configurationRevision = mkIf (self ? rev) self.rev;
  system.stateVersion = "22.05"; # Did you read the comment?
}
