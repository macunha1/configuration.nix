# packages/lua-dbus-proxy -- https://github.com/stefano-m/lua-dbus_proxy
#
# High-level Lua module built on top of lgi to offer a simple API to GLib's GIO
# GDBusProxy objects. Facilitating interactions with DBus interfaces.
#
# Heavily copied from the author's overlay
# Ref: https://github.com/stefano-m/nix-stefano-m-nix-overlays/blob/master/lua/dbus_proxy/default.nix

{ lua, lgi, buildLuaPackage, fetchFromGitHub }:

let
  pname = "dbus_proxy";
  name = "${pname}-${version}";
  version = "0.10.1"; # default version to install

  src = fetchFromGitHub {
    owner = "stefano-m";
    repo = "lua-${pname}";
    rev = "v${version}";
    sha256 = {
      "0.8.5" = "0msxb1hhqq34hv73qkagnassd0h3kj29rzdrhfqs594gw420lry1";
      "0.9.0" = "0s3xl2sbrc494vsh8wqlh5xdmpfl42annm4nmns24ipkqfm3bf2i";
      "0.10.0" = "13qnzhrixv5plnp7hbwp06qq17rsa40z2gpns3f9hgbidpxp08km";
      "0.10.1" = "064xqzc2jvag25s6kq0k5hirpghkfpgyyv1h4f7w5qmvzglxh7kz";
    }."${version}";
  };

in buildLuaPackage rec {
  inherit name src;

  propagatedBuildInputs = [ lgi ];

  buildPhase = ":";

  installPhase = ''
    mkdir -p "$out/share/lua/${lua.luaversion}"
    cp -r src/${pname} "$out/share/lua/${lua.luaversion}/"
  '';
}
