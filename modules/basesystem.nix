{ config, pkgs, options, ... }:

let
in {
  imports = [
    ../overlays

    ./virtualization.nix
    ./docker.nix

    ../users
  ];

  services.fwupd.enable = true;

  # Use the systemd-boot EFI boot loader.
  #boot.loader.systemd-boot.enable = true;
  #boot.loader.efi.canTouchEfiVariables = true;
  boot.blacklistedKernelModules = [
    "uvcvideo" # camera support
  ];

  # /tmp - In RAM and empty after boot
  boot.tmp.cleanOnBoot = true;
  boot.tmp.useTmpfs = true;

  # Don't save access times for files (Less IO for SSD)
  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

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
  };

  # List services that you want to enable:

  # Autorandr
  services.autorandr.enable = true;

  # Remove sound.enable or turn it off if you had it set previously, it seems to cause conflicts with pipewire
  #sound.enable = false;

  # rtkit is optional but recommended
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  fonts.packages= with pkgs; [
    inconsolata
  ];

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

    # Enable the I3 Desktop Environment.
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

      Host duckpond.ch
        ForwardAgent yes
    '';
  };

  # Make vim the default editor
  programs.vim = {
    enable = true;
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
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;

  # Monitor HDDs smart statistics
  services.smartd.enable = true;

  # Mount usb key
  fileSystems."/mnt/usb" = {
    # get using: blkid -sUUID
    device = "UUID=748d4e5b-3528-48ef-982b-8fa8d3c3ba4b";
    fsType = "auto";
    #fsType = "ext3";
    options = [
      #"bind"
      "noauto"
      "users"
      "user"
      "rw"
      "exec"
      #"umask=022"
      #"umask=000"
      #"uid=1000"
      #"gid=1000"
      "x-systemd.automount"
      "x-systemd.device-timeout=5"
    ];
  };

  # Enable tailscale
  services.tailscale = {
    enable = true;
    #extraDaemonFlags = [
    #  "--tun=userspace-networking"
    #  "--socks5-server=localhost:1055"
    #  "--outbound-http-proxy-listen=localhost:1055"
    #];
  };

  # Set trusted users (for cachix)
  nix.settings.trusted-users = [ "root" "ente" ];

}
