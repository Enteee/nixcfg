{ config, pkgs, options, ... }:

let
  utils = pkgs.callPackage ../../utils {};
  xrandr = "${pkgs.xorg.xrandr}/bin/xrandr";
  autorandr = "${pkgs.autorandr}/bin/autorandr";
  sleep = "${pkgs.coreutils}/bin/sleep";

  activateDisplayLink = utils.writeLoggedScript "activateDisplayLink.sh"
    ''
    provider_id="''${1?Missing provider_id}"

    # TODO: How to get the .Xauthority file of
    # the currently logged in user here?
    export DISPLAY=:0
    export XAUTHORITY=/home/ente/.Xauthority

    # Activate display link monitors
    ${xrandr} \
      --setprovideroutputsource \
      "''${provider_id}" 0

    #${autorandr} \
    #  --change
    '' {};

  docked = utils.writeLoggedScript "docked.sh"
    ''
    # TODO: How to get the .Xauthority file of
    # the currently logged in user here?
    export DISPLAY=:0
    export XAUTHORITY=/home/ente/.Xauthority
    '' {};

  undocked = utils.writeLoggedScript "undocked.sh"
    ''
    # TODO: How to get the .Xauthority file of
    # the currently logged in user here?
    export DISPLAY=:0
    export XAUTHORITY=/home/ente/.Xauthority

    (
      # Workaround for:
      # https://github.com/phillipberndt/autorandr/issues/143
      ${sleep} 1
      #${autorandr} \
      #  --change
      #${xrandr} \
      #  --auto
    ) &
    '' {};


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

  # Setprovieroutputsorce when docked
  services.udev.extraRules = ''
    #ACTION=="change", KERNEL=="card1", SUBSYSTEM=="drm", RUN+="${activateDisplayLink} 1"
    #ACTION=="change", KERNEL=="card2", SUBSYSTEM=="drm", RUN+="${activateDisplayLink} 2"

    #SUBSYSTEM=="usb", ACTION=="add", ATTR{idVendor}=="17e9", ATTR{idProduct}=="6015", RUN+="${docked}"

    # we can not use ATTR in remove rules, because:
    # https://unix.stackexchange.com/questions/178341/udev-rule-action-add-is-working-but-action-remove-isnt-working
    #SUBSYSTEM=="usb", ACTION=="remove", ENV{PRODUCT}=="17e9/6015/3104", RUN+="${undocked}"
  '';

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
  # services.printing.enable = true;

  # Enable TLP power management daemon
  services.tlp = {
    enable = true;
  };

  # Enable bluetooth
  services.blueman.enable = true;

  # pulseaudio with bluetooth
  hardware.pulseaudio = {
    extraModules = [ pkgs.pulseaudio-modules-bt ];
  };

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

    # Enable touchpad support.
    libinput.enable = true;

    videoDrivers = [
      "displaylink"
      "modesetting"
    ];

  };

  # screen backlight
  programs.light.enable = true;
  services.actkbd = {
    enable = true;
    bindings = [
      { keys = [ 224 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -U 10"; }
      { keys = [ 225 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -A 10"; }
    ];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?

}
