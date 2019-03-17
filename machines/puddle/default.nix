{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/keepass-duckpond.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  i18n.consoleFont = "latarcyrheb-sun32";

  powerManagement = {
    powertop.enable = true;
    cpuFreqGovernor = "powersave";
  };

  time.timeZone = "Europe/Zurich";

  # Enable u2f fido
  hardware.u2f.enable = true;

  environment.systemPackages = with pkgs; [
    pkgs.nix-index
    pkgs.vim
    pkgs.tmux
    pkgs.autocutsel
    pkgs.htop
    pkgs.home-manager
    pkgs.git
    pkgs.tree
    pkgs.wget
    pkgs.sshfs
    pkgs.rxvt_unicode
    pkgs.urxvt_font_size
    pkgs.modemmanager
    pkgs.firefox
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    # Enable touchpad support.
    libinput.enable = true;

    monitorSection = ''
      DisplaySize 310 175
    '';

    displayManager.lightdm = {
       enable = true;
       greeters.mini = {
         enable = true;
         user = "ente";
       };
    };

    desktopManager = {
      default = "xfce";
      xterm.enable = false;
      xfce = {
        enable = true;
        noDesktop = true;
        enableXfwm = false;
      };
    };

    # Enable the I3 Desktop Environment.
    windowManager = {
      default = "i3";
      i3 = {
        enable = true;
        extraSessionCommands = ''
          autocutsel -fork
          autocutsel -selection PRIMARY -fork
        '';
      };
    };
  };

  fonts.fonts = with pkgs; [
    inconsolata
  ];
  
  users.users.ente = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "networkmanager" "wheel"];
    initialPassword = "gggggg";
    createHome = true;
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

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?

}
