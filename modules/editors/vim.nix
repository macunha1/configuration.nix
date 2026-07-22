# editors/vim.nix -- https://www.vim.org/
#
# For quick edits and writes, Vim suits better (due to its fast load time):
#   open, type, ESC, ESC, ESC, ZZ or :wq, done.

{
  config,
  options,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:
with lib;

let
  inherit (lib.my or (import ../../lib/generators.nix { inherit lib pkgs; }))
    shellExports
    ;

  inherit (lib.my or (import ../../lib/modules.nix { inherit lib; }))
    platformEnv
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  # Fetched once; referenced in both Linux (home.configFile) and Darwin (xdg.configFile).
  vimrcSrc = pkgs.fetchFromGitHub {
    owner = "macunha1";
    repo = "definitely-not-vimrc";
    rev = "2fae56a962aa2213609b6c27d4d775e1473f005c";
    sha256 = "0j15w7q2imlsqvgpmik8fg3f4l7z1gr565ijg941kcxb9bqv9ix7";
  };

  # dein.vim is the plugin manager; fetched separately so it doesn't race
  # with the rest of the vim config directory on first symlink.
  deinSrc = pkgs.fetchFromGitHub {
    owner = "Shougo";
    repo = "dein.vim";
    rev = "21a5c41f0289e98b8086279e62f046b2402dac7c";
    sha256 = "0kcln63kiivc0gyb82hc7ihgf9h2maj7y9ixn83z5sfk0yilmpxb";
  };

  vimAliases = {
    v = "vim";
  };

  vimEnvVars = {
    VIMINIT = "source ${xdg.concrete.config "vim/init.vim"}";
  };
in
{
  options.modules.editors.vim = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.editors.vim.enable (mkMerge [
    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = vimEnvVars;
      darwinTarget = "zsh";
    })

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = with pkgs; [
        editorconfig-core-c # honours .editorconfig in repos
        vim-full # full-featured vim with Python support
      ];

      environment.shellAliases = vimAliases;

      home.configFile."vim" = {
        source = vimrcSrc;
        recursive = true;
      };
      home.configFile."vim/plugins/dein.vim" = {
        source = deinSrc;
        recursive = true;
      };
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      home.packages = with pkgs; [
        editorconfig-core-c # honours .editorconfig in repos
        vim # vim on Darwin (vim_configurable -> vim in recent nixpkgs)
      ];

      modules.shell.zsh.aliases = vimAliases;

      xdg.configFile."vim" = {
        source = vimrcSrc;
        recursive = true;
      };

      xdg.configFile."vim/plugins/dein.vim" = {
        source = deinSrc;
        recursive = true;
      };
    })
  ]);
}
