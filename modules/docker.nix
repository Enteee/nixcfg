{ config, pkgs, ... }:

let
in {

  environment.systemPackages = with pkgs; [
    pkgs.docker_compose
  ];

  virtualisation.docker = {
    enable = true;
  };
}
