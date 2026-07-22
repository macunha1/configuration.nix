# development/ruby.nix -- https://www.ruby-lang.org/en/
#
# > rails new tech-startup
# > rails g scaffold everything
#
# Linux: user.packages + env = rubyEnvVars.
# Darwin: home.packages + home.sessionVariables = rubyEnvVars.

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
  inherit (lib.my or (import ../../lib/modules.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  rubyPackages = with pkgs; [
    ruby_2_7.devEnv # full Ruby dev environment (headers, gems)
    libxml2 # required by Nokogiri and many XML gems
    libxslt # required by Nokogiri XSLT support
  ];

  # Bundler XDG compliance — same paths on both platforms.
  rubyEnvVars = {
    BUNDLE_USER_HOME = xdg.shell.config "bundle";
    BUNDLE_USER_CONFIG = xdg.shell.config "bundle/config";
    BUNDLE_USER_CACHE = xdg.shell.cache "bundle/cache";
    BUNDLE_USER_PLUGIN = xdg.shell.cache "bundle/plugin";
  };
in
{
  options.modules.development.ruby = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.ruby.enable (mkMerge [
    (platformPackages {
      inherit isDarwin;
      packages = rubyPackages;
    })

    (platformEnv {
      inherit config isDarwin;
      envVars = rubyEnvVars;
    })
  ]);
}
