{ config, pkgs, ... }:

{
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
  };

  home-manager.users.ente = { ... }: {
    imports = [
      ./ente.nix
    ];
  };

  # Install packages to /etc/profiles
  # needed for nixos-rebuild build-vm
  home-manager.useUserPackages = true;

  home-manager.useGlobalPkgs = true;

}
