{ inputs, config, lib, pkgs, ... }:

with lib;
with lib.my;
with inputs; {
  imports = [
    # home-manager to manage the dotfiles under $HOME. Mostly using XDG base
    # dir spec for configurations
    inputs.home-manager.nixosModules.home-manager
  ] ++ (mapModulesRec' (toString ./modules) import);

  ## Base Flake configuration
  # Mainly to make 'nix flake' available in the terminal for installation

  environment.variables = {
    DOTFILES = dotFilesDir;

    # Configure nix and nixpkgs, necessary evil
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  nix = let
    filteredInputs = filterAttrs (n: _: n != "self") inputs;
    nixPathInputs = mapAttrsToList (n: v: "${n}=${v}") filteredInputs;
    registryInputs = mapAttrs (_: v: { flake = v; }) filteredInputs;
  in {
    package = pkgs.nixVersions.stable;
    extraOptions = "experimental-features = nix-command";

    nixPath = nixPathInputs ++ [
      "nixpkgs-overlays=${dotFilesDir}/overlays"
      "dotfiles=${dotFilesDir}"
    ];

    registry = registryInputs // { dotfiles.flake = inputs.self; };

    settings = {
      sandbox = true;
      auto-optimise-store = true;

      substituters =
        [ "https://nix-community.cachix.org" "https://nrdxp.cachix.org" ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nrdxp.cachix.org-1:Fc5PSqY2Jm1TrWfm88l6cvGWwz3s93c6IOifQWnhNW4="
      ];
    };
  };

  ## Global defaults
  # Enables 'nix flake check' for hosts even if there's no fileSystem config
  fileSystems."/".device = mkDefault "/dev/disk/by-label/nixos";

  environment.systemPackages = with pkgs; [
    # Nix basics
    cached-nix-shell
    patchelf
    # nix-prefetch # Use `nix store prefetch-file` instead

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
