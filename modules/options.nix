# options.nix -- parameters and convience setup

{
  config,
  options,
  lib,
  home-manager,
  ...
}:

with lib;
with lib.my;
let
  xdg = xdgPaths { inherit config; };

  enabledUnfreePackages =
    optionals config.modules.editors.emacs.enable [ "aspell-dict-en-science" ]
    ++ optionals config.modules.agents.code.claude.enable [ "claude-code" ]
    ++ optionals config.modules.networking.terraform.enable [ "terraform-bin" ]
    ++ optionals config.modules.networking.vagrant.enable [ "vagrant" ]
    ++ optionals config.modules.hardware.video.nvidia.enable [
      "cuda_nvml_dev"
      "nvidia-settings"
      "nvidia-x11"
    ]
    ++ optionals config.modules.media.spotify.enable [ "spotify" ]
    ++ optionals (config.modules.media.spotify.enable && config.modules.media.spotify.daemon.enable) [
      "spotify-player"
    ]
    ++ optionals config.modules.desktop.gaming.steam.enable [
      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"
    ];

  enabledUnfreePackagePrefixes = optionals config.modules.hardware.video.nvidia.enable [
    "cuda"
    "nvidia-"
  ];

  unfreePolicyEnabled = enabledUnfreePackages != [ ] || enabledUnfreePackagePrefixes != [ ];
in
{
  options = with types; {
    user = mkOption {
      type = attrs;
      default = { };
    };

    home = {
      file = mkOption {
        type = attrs;
        default = { };
        description = "Files to place directly in $HOME";
      };

      configFile = mkOption {
        type = attrs;
        default = { };
        description = "Files to place in $XDG_CONFIG_HOME";
      };

      dataFile = mkOption {
        type = attrs;
        default = { };
        description = "Files to place in $XDG_DATA_HOME";
      };
    };

    env = mkOption {
      type = attrsOf (oneOf [
        str
        path
        (listOf (either str path))
      ]);
      apply = mapAttrs (
        n: v: if isList v then concatMapStringsSep ":" (x: toString x) v else (toString v)
      );
      default = { };
      description = "TODO";
    };
  };

  config = {
    user = {
      description = "Default user account";
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      isNormalUser = true;
      name =
        let
          name = builtins.getEnv "USER";
        in
        if
          elem name [
            ""
            "root"
          ]
        then
          "macunha1"
        else
          name;
      # Mainly for Git config and GNU PG
      uid = 1000;
    };

    security.sudo = {
      enable = true;
      wheelNeedsPassword = false; # YOLO
    };

    # Install user packages to /etc/profiles instead. Necessary for
    # nixos-rebuild build-vm to work.
    home-manager = {
      useUserPackages = true;

      # Creating convenience aliases for home-manager, as only a subset of
      # capabilities is accessed and configured in this repository.
      users.${config.user.name} = {
        home = {
          file = mkAliasDefinitions options.home.file;
          # Necessary for home-manager to work with flakes, otherwise it will
          # look for a nixpkgs channel.
          stateVersion = config.system.stateVersion;
        };
        xdg = {
          configFile = mkAliasDefinitions options.home.configFile;
          dataFile = mkAliasDefinitions options.home.dataFile;
        };
      };
    };

    users.users.${config.user.name} = mkAliasDefinitions options.user;

    # Keep unfree access module-scoped. This avoids a global allowUnfree escape
    # hatch while still making enabled feature modules evaluable.
    nixpkgs.config = mkIf unfreePolicyEnabled {
      allowUnfreePredicate =
        pkg:
        let
          packageName = getName pkg;
        in
        elem packageName enabledUnfreePackages
        || any (prefix: hasPrefix prefix packageName) enabledUnfreePackagePrefixes;
    };

    warnings = optional unfreePolicyEnabled ''
      Enabled a scoped nixpkgs allowUnfreePredicate for requested modules: ${
        concatStringsSep ", " (
          enabledUnfreePackages ++ map (prefix: "${prefix}*") enabledUnfreePackagePrefixes
        )
      }
    '';

    nix =
      let
        users = [
          "root"
          config.user.name
        ];
      in
      {
        settings = {
          trusted-users = users;
          allowed-users = users;
        };
      };

    # must already begin with pre-existing PATH.
    env.PATH = [
      (xdg.shell.config "nixos/dotfiles/bin")
      "$HOME/.local/bin"
      "$PATH"
    ];

    environment.extraInit = shellExports config.env;
  };
}
