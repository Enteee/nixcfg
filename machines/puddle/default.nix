{ config, pkgs, options, ... }:

let
  logger = "${pkgs.utillinux}/bin/logger";
  xrandr = "${pkgs.xorg.xrandr}/bin/xrandr";
  autorandr = "${pkgs.autorandr}/bin/autorandr";
  cat = "${pkgs.coreutils}/bin/cat";
  ts = "${pkgs.moreutils}/bin/ts";
  basename = "${pkgs.coreutils}/bin/basename";
  xrdb = "${pkgs.xorg.xrdb}/bin/xrdb";
  sleep = "${pkgs.coreutils}/bin/sleep";

  activateDisplayLink = pkgs.writeScript "activateDisplayLink.sh"
    ''
    #!${pkgs.stdenv.shell}
    # Activate display link monitors
    set -euo pipefail

    CMD="`${basename} "''${0:-udevscript}"`"
    exec 1> >(${logger} -t "''${CMD}")
    exec 2> >(${ts} '[stderr]' | ${logger} -t "''${CMD}")

    DEBUG="''${1:-false}"
    if [ "''${DEBUG}" = true ]; then set -x; fi

    echo "running: ''${0}"
    env

    # TODO: How to get the .Xauthority file of
    # the currently logged in user here?
    export DISPLAY=:0
    export XAUTHORITY=/home/ente/.Xauthority

    provider_id="''${1?Missing provider_id}"

    ${xrandr} \
      --setprovideroutputsource \
      "''${provider_id}" 0

    ${autorandr} \
      --change
    '';

    docked = pkgs.writeScript "docked.sh"
    ''
    #!${pkgs.stdenv.shell}
    # Commands run after docking
    set -euo pipefail

    CMD="`${basename} "''${0:-udevscript}"`"
    exec 1> >(${logger} -t "''${CMD}")
    exec 2> >(${ts} '[stderr]' | ${logger} -t "''${CMD}")

    DEBUG="''${1:-false}"
    if [ "''${DEBUG}" = true ]; then set -x; fi

    echo "running: ''${0}"
    env

    # TODO: How to get the .Xauthority file of
    # the currently logged in user here?
    export DISPLAY=:0
    export XAUTHORITY=/home/ente/.Xauthority

    ${cat} <<EOF | ${xrdb} -merge -
      Xft.dpi:  120
      *.font:   xft:Inconsolata:pixelsize=17:antialias=true
    EOF
    '';

    undocked = pkgs.writeScript "undocked.sh"
    ''
    #!${pkgs.stdenv.shell}
    # Commands run after undocking
    set -euo pipefail

    CMD="`${basename} "''${0:-udevscript}"`"
    exec 1> >(${logger} -t "''${CMD}")
    exec 2> >(${ts} '[stderr]' | ${logger} -t "''${CMD}")

    DEBUG="''${1:-false}"
    if [ "''${DEBUG}" = true ]; then set -x; fi

    echo "running: ''${0}"
    env

    # TODO: How to get the .Xauthority file of
    # the currently logged in user here?
    export DISPLAY=:0
    export XAUTHORITY=/home/ente/.Xauthority

    ${cat} <<EOF | ${xrdb} -merge -
      Xft.dpi:  144
      *.font:   xft:Inconsolata:pixelsize=22:antialias=true
    EOF

    (
      # Workaround for:
      # https://github.com/phillipberndt/autorandr/issues/143
      ${sleep} 1
      ${autorandr} \
        --change
      ${xrandr} \
        --auto
    ) &
    '';


in {
  imports = [
    <nixos-hardware/lenovo/thinkpad/t480s>
    ./hardware-configuration.nix
    ../../modules/virtualization.nix
    ../../modules/keepass-duckpond.nix
    ../../modules/docker.nix
    ../../users
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.blacklistedKernelModules = [
    "uvcvideo" # camera support
  ];

  # /tmp - In RAM and empty after boot
  boot.cleanTmpDir = true;
  boot.tmpOnTmpfs = true;

  # Don't save access times for files (Less IO for SSD)
  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

  boot.initrd.luks.devices = [
    {
      name = "root";
      device = "/dev/disk/by-uuid/07dd092f-0190-492d-ad19-a1fac5849915";
      preLVM = true;
      allowDiscards = true;
    }
  ];

  # support ntfs
  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = "puddle";
  networking.networkmanager.enable = true;
  # disable dhcpcd because networkmanager does trigger dhcp
  networking.dhcpcd.enable = false;

  services.ntp.enable = true;
  networking.timeServers = [
    "metasntp11.admin.ch"
    "metasntp12.admin.ch"
    "metasntp13.admin.ch"
  ] ++ options.networking.timeServers.default;


  # Next line needed, because ModemManager.service
  # does not seem to be started by started when network
  # manager tries to communicate over dbus
  # https://github.com/NixOS/nixpkgs/issues/11197
  systemd.services.ModemManager.wantedBy = [ "multi-user.target" ];

  # Setprovieroutputsorce when docked
  services.udev.extraRules = ''
    ACTION=="change", KERNEL=="card1", SUBSYSTEM=="drm", RUN+="${activateDisplayLink} 1"
    ACTION=="change", KERNEL=="card2", SUBSYSTEM=="drm", RUN+="${activateDisplayLink} 2"

    SUBSYSTEM=="usb", ACTION=="add", ATTR{idVendor}=="17e9", ATTR{idProduct}=="6015", RUN+="${docked}"
    SUBSYSTEM=="usb", ACTION=="remove", ENV{ID_VENDOR_ID}=="17e9", ENV{ID_MODEL_ID}=="6015", RUN+="${undocked} true"
  '';

  i18n.consoleFont = "latarcyrheb-sun32";

  powerManagement = {
    powertop.enable = true;
    cpuFreqGovernor = "powersave";
  };

  time.timeZone = "Europe/Zurich";

  # Enable u2f fido
  hardware.u2f.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    pkgs.nix-index

    pkgs.pciutils
    pkgs.usbutils
    pkgs.moreutils

    pkgs.file
    pkgs.tmux
    pkgs.autocutsel
    pkgs.htop
    pkgs.tree
    pkgs.wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Autorandr
  services.autorandr.enable = true;

  # Fwupd
  #services.fwupd.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  #networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable bluetooth
  services.blueman.enable = true;

  # Enable sound.
  sound = {
    enable = true;
    mediaKeys.enable = true;
  };

  # pulseaudio with bluetooth
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
    extraModules = [ pkgs.pulseaudio-modules-bt ];
  };

  hardware.bluetooth = {
    enable = true;
    extraConfig = "
      [General]
      Enable=Source,Sink,Media,Socket
    ";
  };

  fonts.fonts = with pkgs; [
    inconsolata
  ];

  services.logind.lidSwitch = "suspend";

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    # Enable touchpad support.
    libinput.enable = true;

    videoDrivers = [
      #"intel"
      "displaylink"
    ];

    #monitorSection = ''
    #  DisplaySize 310 175
    #'';

    #extraConfig = ''
    #  Section "OutputClass"
    #    Identifier "DisplayLink"
    #    MatchDriver "evdi"
    #    Driver "modesetting"
    #    Option  "AccelMethod" "none"
    #  EndSection
    #'';

    displayManager.lightdm = {
      enable = true;
      greeters.mini = {
        enable = true;
        user = "ente";
      };
    };

    desktopManager = {
      default = "none";
      xterm.enable = false;
    };

    # Enable the I3 Desktop Environment.
    windowManager = {
      default = "i3";
      i3 = {
        enable = true;
        extraSessionCommands = ''
          # Copy PRIMARY to CLIPBOARD
          # -> Make highlighted text pastable with CTRL+V
          autocutsel -fork

          # Copy CLIPBOARD to PRIMARY
          # -> Make CTR+C pastable with SHIFT+INSERT or by clicking the middle mouse button
          autocutsel -selection PRIMARY -fork

          # Activate autorandr (once)
          # this is needed so that
          # the built vm adjusts resolution
          autorandr -c
        '';
      };
    };
  };

  programs.ssh = {
    startAgent = true;
    extraConfig = ''
      Host *
        ForwardAgent yes
        ServerAliveInterval 60
        ControlPath ~/.ssh/master-%l-%r@%h:%p
        ControlMaster auto

      Host duckpond.ch
        Port 7410
    '';
  };

  # Make vim the default editor
  programs.vim = {
    defaultEditor = true;
  };

  programs.wireshark = {
    enable = true;
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

  # Enable ADB (android debugger)
  programs.adb.enable = true;

}
