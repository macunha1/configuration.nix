{ config, lib, pkgs, ... }:

{
  imports = [
    ./asdf.nix
    ./direnv.nix
    ./fzf.nix
    ./git.nix
    ./gnupg.nix
    ./pass.nix
    ./tmux.nix
    ./zsh.nix
  ];
}
