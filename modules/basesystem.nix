{ config, pkgs, ... }:

{
  imports = [
    ./virtualization.nix
    ./docker.nix

    ../users
  ];

  services.fwupd.enable = true;

  boot.blacklistedKernelModules = [
    "uvcvideo" # camera support
  ];

  # /tmp - In RAM and empty after boot
  boot.tmp.cleanOnBoot = true;
  boot.tmp.useTmpfs = true;

  # Don't save access times for files (Less IO for SSD)
  fileSystems."/".options = [ "noatime" "discard" ];

  # support ntfs
  boot.supportedFilesystems = [ "ntfs" ];

  networking.networkmanager.enable = true;
  # disable dhcpcd because networkmanager does trigger dhcp
  networking.dhcpcd.enable = false;

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
  ];

  programs.gnupg.agent = {
    enable = true;
  };

  # Autorandr
  services.autorandr.enable = true;

  # rtkit is optional but recommended
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  fonts.packages = with pkgs; [
    inconsolata
    font-awesome
    font-awesome_4
    font-awesome_5
  ];

  # Enable the X11 windowing system.
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    displayManager = {
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

    windowManager = {
      i3.enable = true;
    };
  };

  services.displayManager.defaultSession = "none+i3";

  programs.ssh = {
    startAgent = true;
    extraConfig = ''
      Host *
        ServerAliveInterval 60
        ControlPath ~/.ssh/master-%l-%r@%h:%p
        ControlMaster auto

      Host *.ts.net
        ControlMaster no
        ControlPath none
        StrictHostKeyChecking no

      Host duckpond.ch
        ForwardAgent yes
    '';
  };

  programs.wireshark = {
    enable = true;
  };

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
    # chromecast
    8010
  ];

  # Enable firejail setuid binary
  programs.firejail.enable = true;

  # Enable syncthing
  services.syncthing = {
    enable = true;
    dataDir = "/home/syncthing";
  };

  # Avahi (mDNS)
  services.avahi.enable = true;

  # Some programs such as virt-viewer need this
  # meta services to store configuration / passwords
  programs.dconf.enable = true;

  # Monitor HDDs smart statistics
  services.smartd.enable = true;

  # Mount usb key
  fileSystems."/mnt/usb" = {
    # get using: blkid -sUUID
    device = "UUID=748d4e5b-3528-48ef-982b-8fa8d3c3ba4b";
    fsType = "auto";
    options = [
      "noauto"
      "users"
      "user"
      "rw"
      "exec"
      "x-systemd.automount"
      "x-systemd.device-timeout=5"
    ];
  };

  # Enable tailscale
  services.tailscale = {
    enable = true;
  };

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Set trusted users (for cachix)
  nix.settings.trusted-users = [ "root" "ente" ];

}
