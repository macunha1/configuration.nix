{ config, lib, pkgs, ... }:

{
  imports = [
    ./direnv.nix
    ./fzf.nix
    ./git.nix
    ./gnupg.nix
    ./pass.nix
    ./tmux.nix
    ./zsh.nix
  ];
}
