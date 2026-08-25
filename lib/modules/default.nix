{ lib, ... }:

(import ./utils.nix { inherit lib; }) // (import ./agents/mcp.nix { inherit lib; })
