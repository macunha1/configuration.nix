# hardware/nvidia.nix -- https://www.nvidia.com/en-us/
#
# NVIDIA GPU and Graphics module, a must have even if you don't play on Linux.
#
# NVIDIA is a relevant resource to code using CUDA, or train deep learning
# models significantly faster than on CPU.

{ options, config, lib, pkgs, ... }:

with lib; {
  options.modules.hardware.video = {
    # Whether or not to enable OpenGL video/graphical support
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    support32Bit.enable = mkOption {
      type = types.bool;
      default = false;

      description =
        "Whether or not to enable support for 32-bit libraries on 64-bit systems";
    };

    extra32BitPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];

      example = literalExpression ''
        with pkgs.pkgsi686Linux; [
          vaapiIntel
          libvdpau-va-gl
          vaapiVdpau
        ]";
      '';

      description = ''
        Additional packages to add to 32-bit OpenGL drivers on
        64-bit systems. Used when <option>support32Bit</option> is
        enabled.

        This can be used to add OpenCL drivers, VA-API/VDPAU drivers etc.
      '';
    };

    nvidia.enable = mkOption {
      type = types.bool;
      default = false;

      description = "Whether or not to enable NVIDIA graphical drivers";
    };
  };

  config = mkIf config.modules.hardware.video.enable (mkMerge [
    {
      hardware.opengl = {
        enable = true;
        setLdLibraryPath = true;
        driSupport32Bit = config.modules.hardware.video.support32Bit.enable;
      };
    }

    (mkIf config.modules.hardware.video.support32Bit.enable {
      hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
    })

    (mkIf config.modules.hardware.video.nvidia.enable {
      services.xserver.videoDrivers = [ "nvidia" ];

      # NVidia TUI Process Manager, similar to htop.
      # Ref: https://github.com/Syllo/nvtop
      user.packages = with pkgs; [ nvtop ];

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
