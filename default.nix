# default.nix --- let the games begin

device: username:
{ pkgs, options, lib, config, ... }:
{
  networking.hostName = lib.mkDefault device;
  my.username = username;

  imports = [
    ./modules
    "${./hosts}/${device}" # specific hardware configuration
  ];

  ### NixOS
  nix.autoOptimiseStore = true;
  nix.nixPath = options.nix.nixPath.default ++ [
    # So we can use absolute import paths
    "bin=/etc/dotfiles/bin"
    "config=/etc/dotfiles/config"
  ];

  # Add custom packages & unstable channel, so they can be accessed via pkgs.*
  nixpkgs.overlays = import ./packages;

  # Internationalisation
  i18n.defaultLocale = "en_US.UTF-8";

  # These are the things I want installed on all my systems
  environment.systemPackages = with pkgs; [
    # Just the bear necessities~
    coreutils
    git
    unzip
    vim
    curl

    gnumake

    # Mainly used for virtualization
    pciutils

    # Network troubleshooting tools
    nettools
    netcat
    telnet
    nmap
    dnsutils

    openssl

    my.cached-nix-shell # for instant nix-shell scripts
  ];

  environment.shellAliases = {
    nsh  = "nix-shell";
    nenv = "nix-env";
  };

  # Default settings for primary user account. `my` is defined in
  # modules/default.nix
  my.user = {
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"  # Enable ‘sudo’ for the user.
    ];
  };

  security.sudo = {
    enable = true;
    extraRules = [{
      runAs = "ALL:ALL";
      groups = [ "wheel" ];
      commands = [{
        command = "ALL";
        options = [ "NOPASSWD" ]; # YOLO
      }];
    }];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.03"; # Did you read the comment?
}
