# modules/networking/terraform.nix --- https://www.terraform.io/
#
# From the Chaos that is a Systems Engineer life, Terraform is the only constant.
# No matter if you're running a Data Lake, Serverless Web app or embedded system,

{ config, options, lib, pkgs, ... }:
with lib; {
  options.modules.networking.terraform = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.networking.terraform.enable {
    my = {
      # NOTE: Won't work properly, tfenv needs to write in the same path
      # Plus, it follows links (conflicting with NixOS read-only files)
      #
      # home.xdg.dataFile."tfenv" = {
      #   source = pkgs.fetchFromGitHub {
      #     owner = "tfutils";
      #     repo = "tfenv";
      #     rev = "v2.0.0";
      #     sha256 = "0ljx567ykbbdd7974953b9vbyjcf214m189bh2yn1sypaqyynvv6";
      #   };

      #   recursive = true;
      # };

      home.xdg.configFile."terraform/rc.hcl".text = ''
        plugin_cache_dir = "$XDG_CACHE_HOME/terraform/plugins"

        disable_checkpoint           = true
        disable_checkpoint_signature = true
      '';

      env.TF_CLI_CONFIG_FILE = "$XDG_CONFIG_HOME/terraform/rc.hcl";
      env.PATH = [ "$XDG_DATA_HOME/tfenv/bin" ];
    };
  };
}
