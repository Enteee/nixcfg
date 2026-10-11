{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/basesystem.nix
    ../../modules/nosuspend.nix
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

  # powerManagement.powertop.enable is deliberately absent: it runs
  # `powertop --auto-tune` at boot, which flips power/control to "auto" on every
  # USB device, HID included. TLP's own docs warn against running both tuners.
  # The powertop binary is still installed below for diagnostics.

  # Enable TLP power management daemon
  services.tlp = {
    enable = true;
    settings = {
      # Keep USB autosuspend off. The corded mouse and keyboard hang off the
      # DisplayLink dock behind four chained hubs, none of which have remote
      # wakeup enabled, so once the 2s idle timer suspends the mouse its motion
      # reports are dropped until a button press resumes it -- the pointer looks
      # frozen. Autosuspend on a few always-attached peripherals saves almost no
      # power, so disable it wholesale rather than maintaining a USB_DENYLIST
      # that silently breaks whenever a device moves to another dock port.
      USB_AUTOSUSPEND = 0;
    };
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
  environment.systemPackages = [ pkgs.brightnessctl pkgs.powertop ];
  services.actkbd = {
    enable = true;
    bindings = [
      { keys = [ 224 ]; events = [ "key" ]; command = "${lib.getExe pkgs.brightnessctl} set 10%-"; }
      { keys = [ 225 ]; events = [ "key" ]; command = "${lib.getExe pkgs.brightnessctl} set +10%"; }
    ];
  };

  system.stateVersion = "18.09";

}
