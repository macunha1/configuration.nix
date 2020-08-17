{ config, lib, pkgs, ... }:

with lib; {
  options.modules.shell.git = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.shell.git.enable {
    my = {
      packages = with pkgs; [ git ];

      home.xdg.configFile = {
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

          [github]
            user = macunha1

          [gitlab]
            user = macunha
        '';
      };

      alias = {
        # Hard reset master and sync
        "grhh!" = "gf && grhh origin/$(current_branch) && ggpull";
        "gcm!" = "gcm && ggpull"; # Checkout and sync master

        gcmd = concatStringsSep " && " [
          "'CURRENT_BRANCH=$(git_current_branch)'"
          "gcm!"
          "gbd '$CURRENT_BRANCH'"
        ];

        gcmD = concatStringsSep " && " [
          "'CURRENT_BRANCH=$(git_current_branch)'"
          "gcm!"
          "'gbD $CURRENT_BRANCH'"
        ];

        "gstc!" = "gsta && gstc"; # Clear local changes
        gl = "git log";

        "ggpush!" = "gpf! origin '$(git_current_branch)'";
        "gg!" = "gaa && gc! && ggpush!"; # Amend commit and force push
      };
    };
  };
}
