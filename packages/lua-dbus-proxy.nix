# packages/lua-dbus-proxy -- https://github.com/stefano-m/lua-dbus_proxy
#
# High-level Lua module built on top of lgi to offer a simple API to GLib's GIO
# GDBusProxy objects. Facilitating interactions with DBus interfaces.
#
# Heavily copied from the author's overlay
# Ref: https://github.com/stefano-m/nix-stefano-m-nix-overlays/blob/master/lua/dbus_proxy/default.nix

{
  pkgs,
  lib,
  fetchFromGitHub,
  lua ? pkgs.lua,
  luaPackages ? pkgs.luaPackages,
  version ? "master",
}:

let
  pname = "dbus_proxy";
  requestedVersion = version;

  versions = {
    "0.10.0" = {
      rev = "v0.10.0";
      hash = "sha256-dSJw+21xPZjc0PY+8QFROp+AsQGXL3iupbfsHjP8Fo8=";
    };
    "0.10.1" = {
      rev = "v0.10.1";
      hash = "sha256-fx7Y6fu74sKPIzBs7991E76bIywT4Gl0EU9tKdjHnRg=";
    };
    "0.10.2" = {
      rev = "v0.10.2";
      hash = "sha256-1MCqcm4bfPAXDIPwkBYrq65A3V9sFPc/1fXO8IJziE4=";
    };
    "0.10.3" = {
      rev = "v0.10.3";
      hash = "sha256-Yd8TN/vKiqX7NOZyy8OwOnreWS5gdyVMTAjFqoAuces=";
    };
    "0.10.4" = {
      rev = "v0.10.4";
      hash = "sha256-yALxyLx5HeOTgK8r4C/xakcNg1L3t76Y9Dq3pIk5+Rs=";
    };
    master = {
      version = "master-0f84913";
      rev = "0f84913358c1f7ce939b79f071bea9883a75cfb5";
      hash = "sha256-H44JBe2n4QZcQRyQTcYY/DtuG7XQgolPrdPgUU6SJTs=";
    };
  };

  source =
    versions.${requestedVersion}
      or (throw "Unsupported lua-dbus-proxy version: ${requestedVersion}. Supported versions: ${builtins.concatStringsSep ", " (builtins.attrNames versions)}");

in
luaPackages.buildLuaPackage rec {
  inherit pname;
  version = source.version or requestedVersion;

  src = fetchFromGitHub {
    owner = "stefano-m";
    repo = "lua-${pname}";
    inherit (source) rev hash;
  };

  propagatedBuildInputs = [ luaPackages.lgi ];

  buildPhase = ":";

  installPhase = ''
    mkdir -p "$out/share/lua/${lua.luaversion}"
    cp -r src/${pname} "$out/share/lua/${lua.luaversion}/"
  '';

  passthru = {
    inherit requestedVersion;
    availableVersions = builtins.attrNames versions;
    upstreamRev = source.rev;
  };

  meta = {
    description = "Simple API around GLib's GIO:GDBusProxy built on top of lgi";
    homepage = "https://github.com/stefano-m/lua-dbus_proxy";
    license = lib.licenses.asl20;
  };
}
