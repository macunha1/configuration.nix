{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    ./boot.nix
    ./networking.nix
    ./file-systems.nix
    ./modules.nix
  ];

  # GPU and Graphics
  nixpkgs.config = {
    packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    };
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # DP-4 is the main display on the left. HDMI-0 is the physically vertical
  # display on the right and needs a counter-clockwise rotation (-90 degrees,
  # equivalent to +270 degrees).
  services.xserver.displayManager.sessionCommands = ''
    rotate_output() {
      output="$1"
      rotation="$2"

      if ${pkgs.xrandr}/bin/xrandr --query | ${pkgs.gawk}/bin/awk -v output="$output" \
        '$1 == output && $2 == "connected" { found = 1 } END { exit !found }'; then
        ${pkgs.xrandr}/bin/xrandr --output "$output" --rotate "$rotation" || true
      fi
    }

    rotate_output DP-4 normal
    rotate_output HDMI-0 left
    unset -f rotate_output
  '';

  time.timeZone = "Etc/UTC";
  user.extraGroups = [ "networkmanager" ];

  nix = {
    settings.max-jobs = lib.mkDefault 4;

    # Automatic collect garbage to save disk space (which is very limited)
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  hardware.cpu.intel.updateMicrocode = true;
}
