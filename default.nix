# default.nix --- let the games begin

device: username: # parameters

{ pkgs, options, lib, config, ... }: {
  networking.hostName = lib.mkDefault device;
  my.username = username;

  imports = [
    ./modules
    "${./hosts}/${device}" # specific hardware configuration
  ];

  ### NixOS
  nix.autoOptimiseStore = true;
  nix.nixPath = options.nix.nixPath.default ++ [
    # Enables absolute import paths
    "bin=/etc/dotfiles/bin"
    "config=/etc/dotfiles/config"
  ];

  # Add overlays. Available through pkgs.*
  nixpkgs.overlays = import ./packages;

  # Internatiodpandwlaiadisation
  i18n.defaultLocale = "en_US.UTF-8";

  # Bare minimum packages, shared between installations
  environment.systemPackages = with pkgs; [
    coreutils
    dateutils

    git
    unzip
    curl
    openssl

    vim

    cmake
    gnumake

    # Network troubleshooting tools
    nettools
    netcat
    telnet
    nmap
    dnsutils

    my.cached-nix-shell # for instant nix-shell scripts
  ];

  environment.shellAliases = {
    nsh = "nix-shell";
    nenv = "nix-env";
  };

  # Default settings for primary user account. `my` is defined in
  # modules/default.nix
  my.user = {
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
    ];
  };

  my.home.xdg.enable = true;

  environment.variables = {
    XDG_CACHE_HOME = config.my.home.xdg.cacheHome;
    XDG_CONFIG_HOME = config.my.home.xdg.configHome;
    XDG_DATA_HOME = config.my.home.xdg.dataHome;
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false; # YOLO
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.03"; # Did you read the comment?
}
