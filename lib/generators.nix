{ lib, ... }:

with lib;
{
  generatedFileWarning = { file, comment ? "#" }:
    let
      relativePath = removePrefix ((toString ../.) + "/") (toString file);
    in ''
      ${comment} WARNING: DO NOT EDIT. Auto-generated configuration, managed by Nix.
      ${comment}          Changes WILL be overwritten. Implement changes at:
      ${comment}          ${relativePath}
    '';
}
