{
  config,
  lib,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:

let
  inherit (lib.my or (import ../../lib/modules/utils.nix { inherit lib; })) platformPackages;

  cacheUrl = "https://devenv.cachix.org";
  cachePublicKey = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";

  trustedSettings = pkgs.writeText "devenv-trusted-settings.json" (
    builtins.toJSON {
      extra-substituters.${cacheUrl} = true;
      extra-trusted-public-keys.${cachePublicKey} = true;
    }
  );

  # Nix owns this mutable database and has no declarative trust-list option.
  # Merge only these exact approvals, preserving decisions made interactively.
  trustFlakeSettings = pkgs.writeShellApplication {
    name = "trust-devenv-flake-settings";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      settings_dir="$1/nix"
      mkdir -p "$settings_dir"
      settings_file="$settings_dir/trusted-settings.json"
      existing_settings=/dev/null
      if [[ -f "$settings_file" ]]; then
        existing_settings="$settings_file"
      fi

      temporary_file=$(mktemp "$settings_dir/.trusted-settings.XXXXXX")
      trap 'rm -f "$temporary_file"' EXIT
      jq -s 'reduce .[] as $settings ({}; . * $settings)' \
        "$existing_settings" ${trustedSettings} > "$temporary_file"
      if ! cmp -s "$temporary_file" "$settings_file"; then
        mv "$temporary_file" "$settings_file"
      fi
    '';
  };

  homeManagerTrust =
    { config, lib, ... }:
    {
      home.activation.trustDevenvFlakeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${lib.getExe trustFlakeSettings} ${lib.escapeShellArg config.xdg.dataHome}
      '';
    };
in
{
  options.modules.shell.devenv.enable = lib.mkEnableOption "devenv and its trusted binary cache";

  config = lib.mkIf config.modules.shell.devenv.enable (
    lib.mkMerge [
      (platformPackages {
        inherit isDarwin;
        packages = [ pkgs.devenv ];
      })

      (lib.optionalAttrs (!isDarwin) {
        nix.settings = {
          substituters = [ cacheUrl ];
          trusted-public-keys = [ cachePublicKey ];
        };
        home-manager.users.${config.user.name} = homeManagerTrust;
      })

      (lib.optionalAttrs isDarwin (
        lib.mkMerge [
          (homeManagerTrust { inherit config lib; })
          {
            # Standalone Home Manager cannot configure the privileged Nix daemon.
            # The flake's activate app installs this fragment through nix.custom.conf.
            xdg.configFile."nix/devenv-daemon.conf".text = ''
              extra-substituters = ${cacheUrl}
              extra-trusted-public-keys = ${cachePublicKey}
            '';
          }
        ]
      ))
    ]
  );
}
