{ config, lib, pkgs, ... }:

with lib; {
  options.modules.shell.git = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.shell.git.enable {
    user.packages = with pkgs; [ gitAndTools.gh ];

    home.configFile = {
      "git/config".text = ''
        [user]
          name = ${config.my.name}
          email = ${config.my.email}

        [pull]
          rebase = true

        [push]
          default = current

        [rebase]
          autosquash = true
      '';
    };

    environment.shellAliases = {
      gl = "git log";

      "grhh!" = concatStringsSep " && " [
        "gf" # git fetch
        "grhh origin/\\$(current_branch)"
        "ggpull"
      ]; # Hard reset and sync

      "gcm!" = "gcm && ggpull"; # Checkout and sync master

      gcmd = concatStringsSep " && " [
        "CURRENT_BRANCH=\\$(git_current_branch)"
        "gcm!"
        "gbd \\\${CURRENT_BRANCH}"
      ]; # Checkout, sync master and kindly delete branch

      gcmD = concatStringsSep " && " [
        "CURRENT_BRANCH=\\$(git_current_branch)"
        "gcm!"
        "gbD \\\${CURRENT_BRANCH}"
      ]; # Checkout, sync master and delete branch

      "gstc!" = "gaa && gsta && gstc"; # Clear local changes
      "ggpush!" = "gpf! origin \\$(git_current_branch)"; # ggpush + force
      "gg!" = "gaa && gc! && ggpush!"; # Add all, amend and force push
    };
  };
}
