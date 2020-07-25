{ config, lib, pkgs, ... }:

{
  imports = [
    ./direnv.nix
    ./git.nix
    ./gnupg.nix
    ./htop.nix
    ./pass.nix
    ./tmux.nix
    ./zsh.nix
  ];
}
