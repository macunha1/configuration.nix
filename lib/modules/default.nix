{ lib, ... }:

(import ./utils.nix { inherit lib; })
// (import ./agents/integrations.nix { inherit lib; })
// (import ./browser/search-engines.nix { inherit lib; })
