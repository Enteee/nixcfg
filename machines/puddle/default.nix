{ config, pkgs, options, ... }:

let
  utils = pkgs.callPackage ../../utils {};
  xrandr = "${pkgs.xorg.xrandr}/bin/xrandr";
  autorandr = "${pkgs.autorandr}/bin/autorandr";
  sleep = "${pkgs.coreutils}/bin/sleep";
in {
  imports = [
    <nixos-hardware/lenovo/thinkpad/t480s>
    ./hardware-configuration.nix
    ../../modules/basesystem.nix
    ../../users
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

  # Next line needed, because ModemManager.service
  # does not seem to be started by started when network
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

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Fwupd
  # services.fwupd.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  #networking.firewall.enable = false;

  # Enable CUPS to print documents.
  #services.printing.enable = true;
  #services.printing.drivers = [ pkgs.brgenml1lpr pkgs.brgenml1cupswrapper ];

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

  services.logind.lidSwitch = "suspend";

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    videoDrivers = [
      "displaylink"
      "modesetting"
    ];

  };

  # Enable touchpad support.
  services.libinput.enable = true;

  # screen backlight
  programs.light.enable = true;
  services.actkbd = {
    enable = true;
    bindings = [
      { keys = [ 224 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -U 10"; }
      { keys = [ 225 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -A 10"; }
    ];
  };

  # enable mullvad vpn
  services.mullvad-vpn.enable = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?

}
