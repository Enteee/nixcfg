{ pkgs, ... }:

# Everything both machines need that is not a distinct role: hardware,
# networking, base tooling and always-on services.
#
# The role modules -- nix.nix, desktop.nix, gaming.nix -- are imported by each
# machine rather than from here, so `machines/<host>/default.nix` states what
# the host actually is instead of inheriting it implicitly.

{
  imports = [
    ./virtualization.nix
    ./docker.nix
    ./disk-alerts.nix

    ../users
  ];

  services.fwupd.enable = true;

  # Apply CPU microcode updates at boot. This was off, and on pond that was not
  # cosmetic: the kernel reported "Running old microcode" with revision 0x12
  # (the 2012 shipping revision) and listed SRBDS and MDS as "Vulnerable: No
  # microcode". enableRedistributableFirmware was already true -- it ships
  # firmware blobs for devices, but microcode is loaded separately by the
  # kernel's early loader, which needs this option to put it in the initrd.
  hardware.cpu.intel.updateMicrocode = true;

  boot.blacklistedKernelModules = [
    "uvcvideo" # camera support
  ];

  # /tmp - In RAM and empty after boot
  boot.tmp.cleanOnBoot = true;
  boot.tmp.useTmpfs = true;

  # Don't save access times for files (Less IO for SSD)
  #
  # "discard" was dropped deliberately. services.fstrim.enable is already on by
  # default, so the store gets trimmed on a timer, and continuous discard is the
  # worse of the two options here: it issues a TRIM inline with every delete,
  # which on pond's 2012 SandForce SSD is exactly the firmware path with the
  # least testing behind it. Batched fstrim does the same job off the hot path.
  fileSystems."/".options = [ "noatime" ];

  # support ntfs -- removable media only now that pond's Windows disk is gone
  boot.supportedFilesystems = [ "ntfs" ];

  networking.networkmanager.enable = true;
  # disable dhcpcd because networkmanager does trigger dhcp
  networking.dhcpcd.enable = false;

  time.timeZone = "Europe/Zurich";

  console.font = "latarcyrheb-sun32";

  environment.systemPackages = with pkgs; [
    lm_sensors
    pciutils
    usbutils
    moreutils

    # services.smartd.enable only runs the daemon; it does not put the CLI on
    # PATH. Monitoring disks with no way to interrogate them is half a feature.
    smartmontools

    # Stage-2 unlocking goes through systemd-cryptsetup, which ships with
    # systemd, so nothing pulls the cryptsetup CLI in on its own. Needed to
    # inspect keyslots, rotate keys or restore a header backup.
    cryptsetup

    file
    tmux
    htop
    tree
    wget
  ];

  programs.gnupg.agent = {
    enable = true;
  };

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

  # Enable firejail setuid binary
  programs.firejail.enable = true;

  # Enable syncthing
  services.syncthing = {
    enable = true;
    dataDir = "/home/syncthing";
  };

  # Avahi (mDNS)
  services.avahi.enable = true;

  # Monitor HDDs smart statistics. Notifications for smartd -- and for mdadm --
  # are wired up in ./disk-alerts.nix, which replaces the generated notify
  # script with one that reaches the i3 session. NixOS's own x11 path was dead
  # on arrival: notifications.x11.display defaults to ":", and
  # `DISPLAY=: xmessage` fails with "Can't open display".
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
}
