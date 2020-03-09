{ config, pkgs, ... }:

let
in {

  environment.systemPackages = with pkgs; [
    docker_compose
  ];

  virtualisation.docker = {
    enable = true;
  };
}
