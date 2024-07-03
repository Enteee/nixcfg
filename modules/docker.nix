{ config, pkgs, ... }:

let
in {
  virtualisation.docker = {
    enable = true;
  };
}
