{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/basesystem.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/07dd092f-0190-492d-ad19-a1fac5849915";
      preLVM = true;
      allowDiscards = true;
    };
  };

  networking.hostName = "puddle";

  # ModemManager.service does not seem to be started when network
  # manager tries to communicate over dbus
  # https://github.com/NixOS/nixpkgs/issues/11197
  systemd.services.ModemManager.wantedBy = [ "multi-user.target" ];

  services.udev = {
    packages = with pkgs; [
      qFlipper
    ];
  };

  powerManagement = {
    powertop.enable = true;
  };

  # Enable TLP power management daemon
  services.tlp = {
    enable = true;
  };

  # Enable bluetooth
  services.blueman.enable = true;

  # bluetooth with pipewire
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Enable="Source,Sink,Media,Socket";
      };
    };
  };

  services.logind.settings.Login.HandleLidSwitch = "suspend";

  services.xserver = {
    videoDrivers = [
      "displaylink"
      "modesetting"
    ];
  };

  # Enable touchpad support.
  services.libinput.enable = true;

  # Screen backlight. 'light' was removed from nixpkgs in 26.05 (unmaintained
  # upstream); actkbd runs as root, so brightnessctl needs no setuid wrapper.
  environment.systemPackages = [ pkgs.brightnessctl ];
  services.actkbd = {
    enable = true;
    bindings = [
      { keys = [ 224 ]; events = [ "key" ]; command = "${lib.getExe pkgs.brightnessctl} set 10%-"; }
      { keys = [ 225 ]; events = [ "key" ]; command = "${lib.getExe pkgs.brightnessctl} set +10%"; }
    ];
  };

  system.stateVersion = "18.09";

}
