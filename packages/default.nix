[
  (self: super:
    with super; {
      my = {
        uhkAgent = (callPackage ./uhk-agent.nix { });

        cached-nix-shell = (callPackage (builtins.fetchTarball
          "https://github.com/xzfc/cached-nix-shell/archive/master.tar.gz")
          { });

        luaDbusProxy = with pkgs;
          (callPackage ./lua-dbus-proxy.nix {
            inherit (luajitPackages) lua lgi buildLuaPackage;
          });
      };

      # Bleeding edge all the things
      unstable = import <nixpkgs-unstable> { inherit config; };
    })

  # emacsGit
  (import (builtins.fetchTarball
    "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz"))
]
