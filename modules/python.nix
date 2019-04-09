{ config, pkgs, ... }:
let
  python-base-packages = python-packages: with python-packages; [
    ipython
  ];
  python-with-base-packages = pkgs.python3.withPackages python-base-packages;
in {

  environment.systemPackages = with pkgs; [
    python-with-base-packages
  ];

}
