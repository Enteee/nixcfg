{ config, pkgs, ... }:
let
  python-base-packages = python-packages: with python-packages; [
    ipython
    virtualenvwrapper
  ];
  python-with-base-packages = pkgs.python3.withPackages python-base-packages;
in {

  environment.systemPackages = with pkgs; [
    python-with-base-packages
  ];

}
