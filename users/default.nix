{ config, pkgs, lib, systemd, ... }:

with lib;

let
  home-manager = import <home-manager> {};
in
{
  imports = [
    home-manager.nixos
  ];

  home-manager.users.root = { ... }: {
    imports = [
      ./root.nix
    ];
  };

  users.users.ente = {
    isNormalUser = true;

    uid = 1000;
    extraGroups = [
      "wheel"
      "docker"
      "libvirtd"
      "networkmanager"
      "wireshark"
      "adbusers"
      "dialout"
      "tty"
      "vboxusers"
    ];
    initialPassword = "gggggg";
    createHome = true;
    packages = with pkgs; [
    ];

  };

  home-manager.users.ente = { ... }: {
    imports = [
      ./ente.nix
    ];
  };

  # Install packages to /etc/profiles
  # needed for nixos-rebuild build-vm
  home-manager.useUserPackages = true;

}
