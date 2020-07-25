{ config, options, lib, pkgs, ... }:
with lib;
{
  imports = [
    ./emacs.nix
    ./vim.nix
  ];

  options.modules.editors = {
    default = mkOption {
      type = types.str;
      default = "vim";
    };
  };

  config = mkIf (config.modules.editors.default != null) {
    # Helps when using git from the terminal, i.e. 100% of times
    my.env.EDITOR = config.modules.editors.default;
  };
}
