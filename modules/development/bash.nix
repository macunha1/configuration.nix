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
  inherit (lib.my or (import ../../lib/modules/utils.nix { inherit lib; })) platformPackages;
in
{
  options.modules.development.bash = {
    enable = lib.mkEnableOption "Bash development tools";

    languageServer = mkLanguageServerOptions {
      config = config.modules.development.bash.languageServer;
      package = pkgs.bash-language-server;
      arguments = [ "start" ];
      runtimePackages = [
        pkgs.shellcheck
        pkgs.shfmt
      ];
      languageId = "bash";
    };
  };

  config = lib.mkIf config.modules.development.bash.enable (
    lib.mkMerge [
      (platformPackages {
        inherit isDarwin;
        packages = [
          pkgs.bashInteractive
          pkgs.shellcheck
          pkgs.shfmt
        ];
      })

      (lib.mkIf config.modules.development.bash.languageServer.enable (mkLanguageServerContribution {
        inherit isDarwin;
        name = "bash";
        server = config.modules.development.bash.languageServer;
      }))
    ]
  );
}
