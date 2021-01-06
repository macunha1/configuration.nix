# modules/development/ruby.nix --- https://www.ruby-lang.org/en/
#
# > rails new tech-startup
# > rails g scaffold everything

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.development.ruby = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.development.ruby.enable {
    user.packages = with pkgs; [ ruby_2_7.devEnv libxml2 libxslt ];

    env.BUNDLE_USER_HOME = "$XDG_CONFIG_HOME/bundle";
    env.BUNDLE_USER_CONFIG = "$XDG_CONFIG_HOME/bundle/config";
    env.BUNDLE_USER_CACHE = "$XDG_CACHE_HOME/bundle/cache";
    env.BUNDLE_USER_PLUGIN = "$XDG_CACHE_HOME/bundle/plugin";
  };
}
