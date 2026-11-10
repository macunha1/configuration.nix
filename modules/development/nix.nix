{
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:
let
  inherit (lib.my or (import ../../lib/modules/development/language-servers.nix { inherit lib; }))
    mkLanguageServerOptions
    mkLanguageServerContribution
    ;
in
{
  options.modules.development.nix = {
    enable = lib.mkEnableOption "Nix development support";
    languageServer =
      mkLanguageServerOptions {
        config = config.modules.development.nix.languageServer;
        package = pkgs.nixd;
        runtimePackages = [ pkgs.nix ];
        languageId = "nix";
        settings.config_path = toString (
          (pkgs.formats.json { }).generate "nixd-settings.json"
            config.modules.development.nix.languageServer.nixdSettings
        );
      }
      // {
        nixdSettings = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = "nixd package and option expressions for the selected project environment.";
        };
      };
  };

  config =
    lib.mkIf
      (config.modules.development.nix.enable && config.modules.development.nix.languageServer.enable)
      (mkLanguageServerContribution {
        inherit isDarwin;
        name = "nix";
        server = config.modules.development.nix.languageServer;
      });
}
