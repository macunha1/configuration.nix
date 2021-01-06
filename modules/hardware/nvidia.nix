{ options, config, lib, pkgs, ... }:

# Hardware: GPU and Graphics module
# Even if you don't play on Linux NVIDIA is a relevant resource to code using CUDA,
# or train deep learning models significantly faster than on CPU.

with lib; {
  options.modules.hardware.video = {
    # Whether or not to enable OpenGL video/graphical support
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    # Whether or not to enable NVidia video (graphical) drivers
    nvidia.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.hardware.video (mkMerge [
    {
      hardware.opengl = {
        enable = true;
        setLdLibraryPath = true;
        driSupport32Bit = true;
      };
    }

    (mkIf config.modules.hardware.video.nvidia.enable {
      nixpkgs.config.allowUnfree = true; # necessary evil

      services.xserver.videoDrivers = [ "nvidia" ];
      environment.systemPackages = with pkgs;
        [
          # Enforce XDG base dir spec on nvidia settings
          (writeScriptBin "nvidia-settings" ''
            #!${stdenv.shell}
            mkdir -p "$XDG_CONFIG_HOME/nvidia"

            exec ${config.boot.kernelPackages.nvidia_x11.settings}/bin/nvidia-settings \
                --config="$XDG_CONFIG_HOME/nvidia/settings"
          '')
        ];
    })
  ]);
}
