{ self, lib, ... }:

with builtins;
with lib; rec {
  dotFilesDir = toString ../.;
  configDir = "${dotFilesDir}/config";
}
