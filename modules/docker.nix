{ config, pkgs, ... }:

let
in {

  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  virtualisation.docker = {
    enable = true;
  };
}
