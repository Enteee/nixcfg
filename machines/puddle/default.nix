{ config, pkgs, ... }:

let
  activateDisplayLink = pkgs.writeScript "activateDisplayLink.sh"
    ''
    #!${pkgs.stdenv.shell}
    # Activate display link monitors

    export DISPLAY=:0
    export XAUTHORITY=/home/ente/.Xauthority

    # Set provider output source to 0 for all additional providers
    for i in $(seq "$(( $(xrandr --listproviders | wc -l) - 2 ))"); do
      ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource "''${i}" 0
    done
    '';
in {
  imports = [
    <nixos-hardware/lenovo/thinkpad/t480s>
    ./hardware-configuration.nix
    ../../modules/virtualization.nix
    ../../modules/keepass-duckpond.nix
    ../../modules/docker.nix
    ../../modules/python.nix
    ../../users
  ];

  # Force 4.18 Kernel because of evdi (dependency of DisplayLink)
  boot.kernelPackages = pkgs.linuxPackages_4_14;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

  networking.hostName = "puddle";
  networking.networkmanager.enable = true;

  # Next line needed, because mode-manager.service
  # does not seem to be started by started when network
  # manager tries to communicate over dbus
  # https://github.com/NixOS/nixpkgs/issues/11197
  systemd.services.modem-manager.wantedBy = [ "multi-user.target" ];

  # Setprovieroutputsorce when docked
  services.udev.extraRules = ''
    ACTION=="change", KERNEL=="card[0-9]*", SUBSYSTEM=="drm", RUN+="${activateDisplayLink}"
  '';

  i18n.consoleFont = "latarcyrheb-sun32";

  powerManagement = {
    powertop.enable = true;
    cpuFreqGovernor = "powersave";
  };

  time.timeZone = "Europe/Zurich";

  # Enable u2f fido
  hardware.u2f.enable = true;

  hardware.bluetooth.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    pkgs.pciutils
    pkgs.nix-index
    pkgs.file
    pkgs.moreutils
    pkgs.tmux
    pkgs.autocutsel
    pkgs.htop
    pkgs.tree
    pkgs.wget

    pkgs.modemmanager
    pkgs.mobile_broadband_provider_info
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
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound = {
    enable = true;
    mediaKeys.enable = true;
  };
  # hardware.pulseaudio.enable = true;

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

    monitorSection = ''
      DisplaySize 310 175
    '';

    extraConfig = ''
      Section "OutputClass"
        Identifier "DisplayLink"
        MatchDriver "evdi"
        Driver "modesetting"
        Option  "AccelMethod" "none"
      EndSection
    '';

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
          autocutsel -s PRIMARY -fork

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

}
