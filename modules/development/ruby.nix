# development/ruby.nix -- https://www.ruby-lang.org/en/
#
# > rails new tech-startup
# > rails g scaffold everything
#
# Linux: user.packages + env = rubyEnvVars.
# Darwin: home.packages + home.sessionVariables = rubyEnvVars.

{ config, options, lib, pkgs, isDarwin ? pkgs.stdenv.isDarwin, ... }:

with lib;

let
  rubyPackages = with pkgs; [
    ruby_2_7.devEnv # full Ruby dev environment (headers, gems)
    libxml2         # required by Nokogiri and many XML gems
    libxslt         # required by Nokogiri XSLT support
  ];

  ## Bundler XDG compliance — same paths on both platforms.
  rubyEnvVars = {
    BUNDLE_USER_HOME   = "$XDG_CONFIG_HOME/bundle";
    BUNDLE_USER_CONFIG = "$XDG_CONFIG_HOME/bundle/config";
    BUNDLE_USER_CACHE  = "$XDG_CACHE_HOME/bundle/cache";
    BUNDLE_USER_PLUGIN = "$XDG_CACHE_HOME/bundle/plugin";
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

    # Linux (NixOS)
    (optionalAttrs (!isDarwin) {
      user.packages = rubyPackages;
      env = rubyEnvVars;
    })

    # Darwin (MacOS)
    (optionalAttrs isDarwin {
      home.packages = rubyPackages;
      home.sessionVariables = rubyEnvVars;
    })
  ]);
}
