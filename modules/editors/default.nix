{ config, options, lib, pkgs, isDarwin ? pkgs.stdenv.isDarwin, ... }:
with lib; {
  options.modules.editors = {
    default = mkOption {
      type = types.str;
      default = "vim";
    };
  };

  config = mkIf (config.modules.editors.default != null) (mkMerge [
    (optionalAttrs (!isDarwin) {
      env.EDITOR = config.modules.editors.default;
    })
    (optionalAttrs isDarwin {
      home.sessionVariables.EDITOR = config.modules.editors.default;
    })
  ]);
}
