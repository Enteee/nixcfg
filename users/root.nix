{ pkgs, options, config, lib, ... }:

let
in {
  imports = [
    ../overlays

    ../programs/vim.nix
  ];
}
