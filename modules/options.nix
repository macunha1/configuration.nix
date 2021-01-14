# options.nix -- parameters and convience setup

{ config, options, lib, home-manager, ... }:

with lib;
with lib.my; {
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
      type = attrsOf (oneOf [ str path (listOf (either str path)) ]);
      apply = mapAttrs (n: v:
        if isList v then
          concatMapStringsSep ":" (x: toString x) v
        else
          (toString v));
      default = { };
      description = "TODO";
    };
  };

  config = {
    user = {
      description = "Default user account";
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      isNormalUser = true;
      name = let name = builtins.getEnv "USER";
      in if elem name [ "" "root" ] then "macunha1" else name;
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

    nix = let users = [ "root" config.user.name ];
    in {
      trustedUsers = users;
      allowedUsers = users;
    };

    # must already begin with pre-existing PATH. Also, can't use binDir here,
    # because it contains a nix store path.
    env.PATH = [ "$XDG_CONFIG_HOME/dotfiles/bin" "$PATH" ];

    environment.extraInit = concatStringsSep "\n"
      (mapAttrsToList (n: v: ''export ${n}="${v}"'') config.env);
  };
}
