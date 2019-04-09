{ pkgs, options, config, lib, ... }:

let
in {
  imports = [
    ../programs/git.nix
    ../programs/vim.nix
  ];
}
