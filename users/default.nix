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

  systemd.services.home-manager-ente.preStart = ''
      # XXX: Dummy nix-env command to work around:
      # https://github.com/rycee/home-manager/issues/948
      ${pkgs.nix}/bin/nix-env -i -E
  '';


  # Install packages to /etc/profiles
  # needed for nixos-rebuild build-vm
  home-manager.useUserPackages = true;

}
