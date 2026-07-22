# shell/git.nix -- https://git-scm.com/
#
# A god-send in terms of software version control.
#
# Both platforms share a single gitSettings attrset.
# Linux  -> lib.generators.toGitINI serialises it to an INI file via home.configFile.
# Darwin -> programs.git.settings consumes the attrset directly.

{
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

with lib;

let
  # Some standalone evaluations pass plain nixpkgs.lib, so lib.my may be absent.
  # Import the generator directly in that case.
  inherit (lib.my or (import ../../lib/generators.nix { inherit lib pkgs; }))
    generatedFileWarning
    shellExports
    ;

  inherit (lib.my or (import ../../lib/modules.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  hasEmail = config.modules.shell.git.user.email != "";
  hasGpg = config.modules.shell.git.user.gpgSigningKeyId != "";

  hostedGitCliPackages =
    optionals config.modules.shell.git.githubCli.enable [ pkgs.gh ]
    ++ optionals config.modules.shell.git.gitlabCli.enable [ pkgs.glab ];

  gitEnvVars = {
    GIT_CONFIG_GLOBAL = xdg.concrete.config "git/config";
  };

  ohMyZshGitPlugin = rec {
    rev = "93c837fec8e9fe61509b9dff9e909e84f7ebe32d";
    url = "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/" + rev + "/plugins/git/git.plugin.zsh";
    hash = "sha256-lzToZgFVpNxN3yszVytFxPJlTFLhGedxarpc7vK4L5g=";
  };

  # Canonical git configuration - defined once, used by both platforms.
  # lib.generators.toGitINI and programs.git.settings both accept this shape.
  gitSettings = {
    user = {
      name = config.modules.shell.git.user.name;
      useconfigonly = true;
    }
    // optionalAttrs hasEmail { email = config.modules.shell.git.user.email; }
    // optionalAttrs hasGpg {
      signingkey = config.modules.shell.git.user.gpgSigningKeyId;
    };
  }
  // optionalAttrs hasGpg { commit.gpgsign = true; }
  // {
    pull.rebase = true;
    push.default = "current";
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
    "gm!" = concatStringsSep " && " [
      "GIT_CURRENT_BRANCH=$(git_current_branch)"
      "gcm"
      "gm \${GIT_CURRENT_BRANCH}"
      "ggpush"
      "gco \${GIT_CURRENT_BRANCH}"
      "gcmd"
    ];

    "gstc!" = "gaa && gsta && gstc"; # stash and clear local changes
    "ggpush!" = "ggpush --force"; # explicit force-push
    "gg!" = "gaa && gc! && ggpush!"; # add all, amend, force-push
  };

  # OMZ git.plugin.zsh - single-file fetch; provides all standard git shell aliases.
  # The companion lib/git.zsh helper functions are inlined as gitHelperFunctions below.
  gitOmzPlugin = pkgs.fetchurl { inherit (ohMyZshGitPlugin) url hash; };

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
        default =
          let
            n = builtins.getEnv "USER";
          in
          if
            elem n [
              ""
              "root"
            ]
          then
            "macunha1"
          else
            n;
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

    githubCli.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether or not to install GitHub CLI";
    };

    gitlabCli.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether or not to install GitLab CLI";
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
      home.configFile."git/config".text =
        generatedFileWarning { file = ./git.nix; } + generators.toGitINI gitSettings;

      environment.shellAliases = gitAliases;
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      programs.git = {
        enable = true;
        settings = gitSettings;
      };

      modules.shell.zsh.aliases = gitAliases;
    })

    (platformPackages {
      inherit isDarwin;
      packages = hostedGitCliPackages;
    })

    # Explicit override so tools that create ~/.gitconfig (Homebrew, Xcode CLI)
    # cannot silently shadow the XDG-managed config.
    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = gitEnvVars;
      darwinTarget = "zsh";
    })
  ]);
}
