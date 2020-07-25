{ config, lib, pkgs, makeDesktopItem, appimageTools, ... }:

let pname = "uhk-agent";
    version = "1.3.0";
    desktopItem = makeDesktopItem {
      name = pname;
      desktopName = "UHK Agent";
      comment = "Ultimate Hacking Keyboard configuration agent";
      icon = "keyboard";
      terminal = "false";
      exec = pname;
      categories = "Settings;";
    };

in pkgs.appimageTools.wrapType2 rec {
  name = "uhk-agent-${version}";
  src = builtins.fetchurl {
    url = "https://github.com/UltimateHackingKeyboard/agent/releases/download/v${version}/UHK.Agent-${version}-linux-x86_64.AppImage";
    sha256 = {
      # version >1.3.0 causes it to hang on launch ("Loading configuration. Hang on")
      "1.2.12" = "1gr3q37ldixcqbwpxchhldlfjf7wcygxvnv6ff9nl7l8gxm732l6";
      "1.3.0" =  "09k09yn0iyivc9hf283cxrcrcyswgg2jslc85k4dwvp1pc6bpp07";
      "1.3.1" =  "0inps9q6f6cmlnl3knmfm2mmgqb5frl4ghxplbzvas7kmrd2wg4k";
      "1.3.2" =  "1y2n2kkkkqsqxw7rsya7qxh8m5nh0n93axcssi54srp3h7040w3h";
      "1.4.0" =  "1y6gy3zlj0pkvydby7ibm7hx83lmc3vs2m0bfww5dq1114j99dy5";
    }."${version}";
  };

  xdg_dirs = builtins.concatStringsSep ":" [
    "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
  ];

  # not necessary, here for debugging purposes
  # adapted from the original runScript of appimageTools
  extracted_source = pkgs.appimageTools.extractType2 { inherit name src; };
  debugScript = pkgs.writeScript "run" ''
      #!${pkgs.stdenv.shell}

    export APPDIR=${extracted_source}
    export APPIMAGE_SILENT_INSTALL=1

    # >>> inspect the script running environment here <<<
    echo "INSPECT: ''${GIO_EXTRA_MODULES:-no extra modules!}"
    echo "INSPECT: ''${GSETTINGS_SCHEMA_DIR:-no schemas!}"
    echo "INSPECT: ''${XDG_DATA_DIRS:-no data dirs!}"

    cd $APPDIR
    exec ./AppRun "$@"
  '';

  # for debugging purposes only
  # runScript = debugScript;
  multiPkgs = null; # no 32bit needed
  extraPkgs = p: (appimageTools.defaultFhsEnvArgs.multiPkgs p);

  extraInstallCommands = ''
    ln -s "$out/bin/${name}" "$out/bin/uhk-agent";
    mkdir -p $out/etc/udev/rules.d
    cat > $out/etc/udev/rules.d/50-uhk60.rules <<EOF
    # Ultimate Hacking Keyboard rules
    # These are the udev rules for accessing the USB interfaces of the UHK as non-root users.
    # Copy this file to /etc/udev/rules.d and physically reconnect the UHK afterwards.
    SUBSYSTEM=="input", GROUP="input", MODE="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="612[0-7]", MODE:="0666", GROUP="plugdev"
    KERNEL=="hidraw*", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="612[0-7]", MODE="0666", GROUP="plugdev"
    EOF
  '';

  profile = ''
    export XDG_DATA_DIRS="${xdg_dirs}''${XDG_DATA_DIRS:+:}"
    export APPIMAGE=''${APPIMAGE-""} # Kill a seemingly useless error message
  '';

  meta = with lib; {
    homepage = "https://github.com/linode/linode-cli";
    description = "The Linode CLI";
    license = licenses.bsd3;
    maintainers = [ maintainers.hlissner ];
  };
}
