# shell/git.nix -- https://git-scm.com/
#
# A god-send in terms of software version control.
#
# Both platforms share a single gitSettings attrset.
# Linux  -> lib.generators.toGitINI serialises it to an INI file via home.configFile.
# Darwin -> programs.git.settings consumes the attrset directly.

{ config, lib, pkgs, isDarwin ? pkgs.stdenv.isDarwin, ... }:

with lib;

let
  cfg = config.modules.shell.git.user;

  hasEmail = cfg.email != "";
  hasGpg   = cfg.gpgSigningKeyId != "";

  # Canonical git configuration - defined once, used by both platforms.
  # lib.generators.toGitINI and programs.git.settings both accept this shape.
  gitSettings = {
    user = { name = cfg.name; useconfigonly = true; }
      // optionalAttrs hasEmail { email = cfg.email; }
      // optionalAttrs hasGpg   { signingkey = cfg.gpgSigningKeyId; };
  } // optionalAttrs hasGpg {
    commit.gpgsign = true;
  } // {
    pull.rebase    = true;
    push.default   = "current";
    rebase.autosquash = true;
  };

  # Shell aliases are identical on both platforms; only the option name differs.
  gitAliases = {
    gl = "git log";

    # Fetch + hard-reset current branch to origin, then pull
    "grhh!" = "gf && grhh origin/$(git_current_branch) && ggpull";

    # Checkout master/main and pull
    "gcm!" = "gcm && ggpull";

    # Checkout master and (kindly) delete the old branch
    gcmd = "CURRENT_BRANCH=$(git_current_branch) && gcm! && gbd $CURRENT_BRANCH";
    # Same but force-delete
    gcmD = "CURRENT_BRANCH=$(git_current_branch) && gcm! && gbD $CURRENT_BRANCH";

    # Merge current branch into master, push, return to branch, then delete it
    "gm!" = "GIT_CURRENT_BRANCH=$(git_current_branch) && gcm && gm \${GIT_CURRENT_BRANCH} && ggpush && gco \${GIT_CURRENT_BRANCH} && gcmd";

    "gstc!" = "gaa && gsta && gstc"; # stash and clear local changes
    "ggpush!" = "ggpush --force";    # explicit force-push
    "gg!" = "gaa && gc! && ggpush!"; # add all, amend, force-push
  };

  # OMZ git.plugin.zsh - single-file fetch; provides all standard git shell aliases.
  # The companion lib/git.zsh helper functions are inlined as gitHelperFunctions below.
  gitOmzPlugin = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/93c837fec8e9fe61509b9dff9e909e84f7ebe32d/plugins/git/git.plugin.zsh";
    sha256 = "161gp3rfwp5sd9qyf6g1a966bwn48lmmfcrbvx6xr92m05kfhd4p";
  };

  # Inline replacements for the lib/git.zsh helpers called by git.plugin.zsh.
  #
  # git_current_branch: git 2.22+ --show-current; returns empty in detached HEAD
  # (no symbolic-ref dance needed).
  #
  # git_main_branch: probes local refs in preference order (main -> trunk -> master)
  # and falls back to "main". No deprecated git_develop_branch / git_root_branch.
  gitHelperFunctions = ''
    function git_current_branch() {
      git branch --show-current 2>/dev/null
    }

    function git_main_branch() {
      command git rev-parse --git-dir &>/dev/null || return
      for branch in main trunk master; do
        command git show-ref -q --verify "refs/heads/$branch" && { echo "$branch"; return; }
      done
      echo main
    }
  '';
in
{
  options.modules.shell.git = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

    user = {
      name = mkOption {
        type = types.str;
        # Fall back to $USER so this works outside a NixOS user context (standalone HM).
        default = let n = builtins.getEnv "USER";
          in if elem n [ "" "root" ] then "macunha1" else n;
        description = "git/config user.name";
      };

      email = mkOption {
        type = types.str;
        default = "";
        description = "git/config user.email";
      };

      gpgSigningKeyId = mkOption {
        type = types.str;
        default = "";
        description = "git/config user.signingkey for commit signing";
      };
    };
  };

  config = mkIf config.modules.shell.git.enable (mkMerge [

    # Both platforms: source helper functions then the plugin itself into init.zsh.
    (mkIf config.modules.shell.zsh.enable {
      modules.shell.zsh.init = gitHelperFunctions + ''
        source ${gitOmzPlugin}
      '';
    })

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = with pkgs; [
        gitAndTools.gh # GitHub CLI
      ];

      home.configFile."git/config".text = generators.toGitINI gitSettings;

      # Explicit so NixOS and Darwin stay consistent: both declare GIT_CONFIG_GLOBAL.
      env.GIT_CONFIG_GLOBAL = "$XDG_CONFIG_HOME/git/config";

      environment.shellAliases = gitAliases;
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      home.packages = with pkgs; [
        gh # GitHub CLI
      ];

      programs.git = {
        enable = true;
        settings = gitSettings;
      };

      # Explicit override so tools that create ~/.gitconfig (Homebrew, Xcode CLI)
      # cannot silently shadow the XDG-managed config.
      modules.shell.zsh.env = ''
        export GIT_CONFIG_GLOBAL="${config.xdg.configHome}/git/config"
      '';

      modules.shell.zsh.aliases = gitAliases;
    })
  ]);
}
