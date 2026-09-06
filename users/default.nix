{ config, pkgs, inputs, ... }:

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

  # Rename conflicting files instead of aborting activation. Declaratively
  # installed Firefox extensions collide with copies Firefox installed itself.
  home-manager.backupFileExtension = "hm-bak";

  # Make flake inputs (e.g. firefox-addons) available to home-manager modules
  home-manager.extraSpecialArgs = { inherit inputs; };

}
