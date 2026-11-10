# development/elixir.nix -- https://elixir-lang.org/
#
# Erlang taken to the next level. Or is it a better Ruby?

{
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:

with lib;

let
  inherit (lib.my or (import ../../lib/modules/development/language-servers.nix { inherit lib; }))
    mkLanguageServerOptions
    mkLanguageServerContribution
    ;
  inherit (lib.my or (import ../../lib/generators.nix { inherit lib pkgs; }))
    shellExports
    ;

  inherit (lib.my or (import ../../lib/modules/utils.nix { inherit lib; }))
    platformEnv
    platformPackages
    ;

  xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
    inherit config isDarwin;
  };

  elixirPackages = with pkgs.beam29Packages; [
    elixir_1_20
    erlang # exposes erl/escript for Mix dependencies compiled through rebar3
  ];

  elixirEnvVars = {
    MIX_HOME = config.modules.development.elixir.mix.path;
    HEX_HOME = config.modules.development.elixir.hex.path;
  };
in
{
  options.modules.development.elixir = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    languageServer = mkLanguageServerOptions {
      config = config.modules.development.elixir.languageServer;
      package = pkgs.beam29Packages.expert;
      arguments = [ "--stdio" ];
      runtimePackages = elixirPackages;
      environment = elixirEnvVars;
      languageId = "elixir";
    };

    # Elixir package manager
    mix = {
      path = mkOption {
        type = with types; (either str path);
        default = xdg.concrete.data "mix";
      };
    };

    hex = {
      path = mkOption {
        type = with types; (either str path);
        default = xdg.concrete.data "hex";
      };
    };
  };

  config = mkIf config.modules.development.elixir.enable (mkMerge [
    (mkIf config.modules.development.elixir.languageServer.enable (mkLanguageServerContribution {
      inherit isDarwin;
      name = "elixir";
      server = config.modules.development.elixir.languageServer;
    }))
    (platformPackages {
      inherit isDarwin;
      packages = elixirPackages;
    })

    (platformEnv {
      inherit config isDarwin;
      inherit shellExports;
      envVars = elixirEnvVars;
      target = "both";
    })
  ]);
}
