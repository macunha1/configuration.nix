[
  (self: super: with super; {
    my = {
      uhkAgent = (callPackage ./uhk-agent.nix {});
      cached-nix-shell =
        (callPackage
          (builtins.fetchTarball
            https://github.com/xzfc/cached-nix-shell/archive/master.tar.gz) {});

    };

    # Bleeding edge all the things
    unstable = import <nixos-unstable> { inherit config; };
  })

  # emacsGit
  (import (builtins.fetchTarball https://github.com/nix-community/emacs-overlay/archive/master.tar.gz))
]
