# shell/git.nix -- https://git-scm.com/
#
# A god-send in terms of software version control.

{ config, lib, pkgs, ... }:

with lib; {
  options.modules.shell.git = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

    user = {
      name = mkOption {
        type = types.str;
        default = config.user.name;
        description = "git/config user.name to configure for commits";
      };

      email = mkOption {
        type = types.str;
        default = "";
        description = "git/config user.email to configure for commits";
      };

      gpgSigningKeyId = mkOption {
        type = types.str;
        default = "";
        description = "git/config user.signingkey to sign commits";
      };
    };
  };

  config = mkIf config.modules.shell.git.enable {
    user.packages = with pkgs; [ gitAndTools.gh ];

    home.configFile = {
      "git/config".text = ''
        [user]
          name = ${config.modules.shell.git.user.name}
          useconfigonly = true

        ${if config.modules.shell.git.user.email != "" then ''
          email = ${config.modules.shell.git.user.email}
        '' else
          ""}

        ${if config.modules.shell.git.user.gpgSigningKeyId != "" then ''
          signingkey = ${config.modules.shell.git.user.gpgSigningKeyId}

          [commit]
            gpgsign = true'' else
          ""}

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
        "grhh origin/$(current_branch)"
        "ggpull"
      ]; # Hard reset and sync

      "gcm!" = "gcm && ggpull"; # Checkout and sync master

      gcmd = concatStringsSep " && " [
        "CURRENT_BRANCH=$(git_current_branch)"
        "gcm!"
        "gbd \${CURRENT_BRANCH}"
      ]; # Checkout, sync master and kindly delete branch

      gcmD = concatStringsSep " && " [
        "CURRENT_BRANCH=$(git_current_branch)"
        "gcm!"
        "gbD \${CURRENT_BRANCH}"
      ]; # Checkout, sync master and delete branch

      "gstc!" = "gaa && gsta && gstc"; # Clear local changes
      "ggpush!" = "ggpush --force"; # git push origin $BRANCH_NAME --force
      "gg!" = "gaa && gc! && ggpush!"; # Add all, amend and force push
    };
  };
}
