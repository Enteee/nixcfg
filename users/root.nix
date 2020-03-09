{ pkgs, options, config, lib, ... }:

let
in {
  imports = [
    ../overlays
    ../programs/git.nix
    ../programs/vim.nix
  ];
}
