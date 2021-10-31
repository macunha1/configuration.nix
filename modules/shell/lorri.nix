# shell/lorri.nix -- https://github.com/nix-community/lorri
#
# Lorri improves considerably the development experience when using Nix.
# Put it together with `direnv` and aim for the moon.

{ config, home-manager, options, lib, pkgs, ... }:

with lib; {
  options.modules.shell.lorri = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.lorri.enable {
    services.lorri.enable = true;

    # Create the symlink to $XDG_CONFIG_HOME/systemd/user/lorri
    # equivalent to `systemctl --user enable lorri`
    home-manager.users.${config.user.name}.services.lorri.enable = true;
  };
}
