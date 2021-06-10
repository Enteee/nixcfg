{ config, pkgs, options, ... }:

let
in {
  imports = [
    ../overlays

    ./virtualization.nix
    ./keepass-duckpond.nix
    ./docker.nix

    ../users
  ];

  # Use the systemd-boot EFI boot loader.
  #boot.loader.systemd-boot.enable = true;
  #boot.loader.efi.canTouchEfiVariables = true;
  boot.blacklistedKernelModules = [
    "uvcvideo" # camera support
  ];

  # /tmp - In RAM and empty after boot
  boot.cleanTmpDir = true;
  boot.tmpOnTmpfs = true;

  # Don't save access times for files (Less IO for SSD)
  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

  # support ntfs
  boot.supportedFilesystems = [ "ntfs" ];

  networking.networkmanager.enable = true;
  # disable dhcpcd because networkmanager does trigger dhcp
  networking.dhcpcd.enable = false;

  services.ntp.enable = true;
  time.timeZone = "Europe/Zurich";

  console.font = "latarcyrheb-sun32";

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    nix-index

    lm_sensors
    pciutils
    usbutils
    moreutils

    file
    tmux
    htop
    tree
    wget

    rxvt-unicode-unwrapped.terminfo
  ];

  /*
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  */

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "qt";
  };

  # List services that you want to enable:

  # Autorandr
  services.autorandr.enable = true;

  # Enable sound.
  sound = {
    enable = true;
    mediaKeys.enable = true;
  };

  # pulseaudio with bluetooth
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };

  fonts.fonts = with pkgs; [
    inconsolata
  ];

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    displayManager = {

      defaultSession = "none+i3";

      lightdm = {
        enable = true;
        greeters.mini = {
          enable = true;
          user = "ente";
        };
      };
    };

    desktopManager = {
      xterm.enable = false;
    };

    # Enable the I3 Desktop Environment.
    windowManager = {
      i3.enable = true;
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

      Host *.duckpond.ch
        Port 7410

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

  # Enable ADB (android debugger)
  programs.adb.enable = true;

  # Enable Steam
  programs.steam.enable = true;
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 27031;
      to = 27036;
    }
  ];
  networking.firewall.allowedTCPPorts = [
    27036
  ];

  # Enable firejail setuid binary
  programs.firejail.enable = true;

  # Enable syncthing
  services.syncthing = {
    enable = true;
    dataDir = "/home/syncthing";
  };

  # Some programs such as virt-viewer need this
  # this meta services to store configuration / passwords
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;

  # Monitor HDDs smart statistics
  services.smartd.enable = true;
}
