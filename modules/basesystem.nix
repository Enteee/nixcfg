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
  networking.timeServers = [
    "metasntp11.admin.ch"
    "metasntp12.admin.ch"
    "metasntp13.admin.ch"
  ] ++ options.networking.timeServers.default;


  console.font = "latarcyrheb-sun32";

  time.timeZone = "Europe/Zurich";

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

  # Enable 32 Bit Support (for Steam)
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.pulseaudio.support32Bit = true;
  hardware.steam-hardware.enable = true;

  # Enable firejail setuid binary
  programs.firejail = {
    enable = true;
  };

  # Some programs such as virt-viewer need this
  # this meta services to store configuration / passwords
  services.gnome3.gnome-keyring.enable = true;
  programs.dconf.enable = true;
}
