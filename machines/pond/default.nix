{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../../modules/basesystem.nix
    ../../modules/nix.nix
    ../../modules/desktop.nix
    ../../modules/gaming.nix

    ../../modules/nosuspend.nix
    ../../modules/wd-idle3.nix
  ];

  # Use the GRUB 2 boot loader.
  #
  # Addressed by-id rather than /dev/sda: this box has four disks and kernel
  # enumeration order is not a promise. If sda ever came up as something else,
  # activation would install the bootloader into the MBR of the wrong disk.
  boot.loader.grub.enable = true;
  boot.loader.grub.device =
    "/dev/disk/by-id/ata-OCZ-VERTEX3_OCZ-T59P986F6605K4SH";

  # useOSProber is deliberately absent: the Windows install it existed to find
  # is gone, and os-prober scans every disk on each activation to produce
  # nothing.

  networking.hostName = "pond";

  # ---------------------------------------------------------------------------
  # TEMPORARY -- remove when the pond migration is finished.
  #
  # Granted so the migration can run unattended. It has to live here rather than
  # in /etc/sudoers.d because NixOS regenerates /etc/sudoers from this config on
  # every activation: an out-of-band grant is destroyed by the next
  # `nixos-rebuild switch`, which is exactly what happened on the first one.
  #
  # Scoped to ente on pond only -- deliberately not security.sudo.wheelNeedsPassword,
  # which would cover every wheel member on both machines.
  #
  # To revoke: delete this block and `nixos-rebuild switch`.
  # ---------------------------------------------------------------------------
  security.sudo.extraRules = [
    {
      users = [ "ente" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # /home lives on the md array -- 5400rpm spinning rust, where the atime write
  # amplification costs considerably more than it does on the SSD holding /.
  fileSystems."/home".options = [ "noatime" ];

  # Set explicitly rather than inherited. boot.swraid.enable defaults to
  # `versionOlder config.system.stateVersion "23.11"`, so this array has only
  # ever assembled because stateVersion is 20.03 -- raising it would have
  # silently stopped /home from mounting. Nothing in this repo referenced mdadm
  # at all before now.
  # The PROGRAM line that makes array events visible -- and that keeps mdmon
  # from crashing on an otherwise empty mdadm.conf -- is in
  # ../../modules/disk-alerts.nix, shared with smartd. mdadmConf is types.lines,
  # so the ARRAY line below merges with it.
  #
  # The ARRAY line is safe to pin now. It was not before: the old array's
  # superblock said homehost `pond1` while the host is `pond`, so mdadm treated
  # it as foreign, assembled it as a numbered /dev/md127 with no /dev/md/<name>
  # symlink, and an ARRAY line made it canonicalise to a /dev/md/md127 that did
  # not exist -- emitting a spurious DeviceDisappeared on every scan. The
  # rebuilt array is created with --homehost=pond --name=home, so /dev/md/home
  # is real and the mismatch is gone.
  boot.swraid = {
    enable = true;
    mdadmConf = ''
      ARRAY /dev/md/home metadata=1.2 name=pond:home UUID=1c658113:dc78dc8a:ee5c29b3:7fb7e336
    '';
  };

  # /home's LUKS container is opened in stage 2 rather than the initrd: nothing
  # on /home is needed to boot, and the keyfile lives on root, which is mounted
  # by then. systemd's cryptsetup generator turns this into
  # systemd-cryptsetup@crypthome.service, which the /home mount requires.
  #
  # Keyed by LUKS UUID, not /dev/md/home, so it does not depend on mdadm naming.
  #
  # Note the keyfile sits on a *plaintext* root until Track 3 encrypts it, so
  # /home's encryption is not yet meaningful -- anyone with the root disk has
  # the key. That changes when root moves to LUKS; the keyfile is carried over
  # in the Track 3 state tarball. Keyslot 1 holds a recovery passphrase, which
  # is the fallback if that tarball is ever wrong.
  environment.etc.crypttab.text = ''
    crypthome UUID=596aecda-8a3c-46a6-9d39-e24692eeb78d /etc/luks-keys/home luks
  '';

  services.xserver = {
    videoDrivers = [
      "nvidia"
    ];
  };

  # Both GPUs here are Kepler (GK104: GTX 680 and GTX 660 Ti), which the
  # current driver branch no longer supports -- it loads, finds no GPU it
  # recognises ("NVRM: No NVIDIA GPU found"), and unregisters itself, so the X
  # server has no driver to start on. Kepler's last supported branch is 470.
  #
  # other options are: legacy_340 legacy_470 stable beta vulkan_beta
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_470;

  # 470 predates the open kernel modules, so the source tarball is only
  # fetched once the NVIDIA license is accepted. Newer branches ship an
  # openSha256 and skip this check, which is why it was not needed before.
  nixpkgs.config.nvidia.acceptLicense = true;

  # Required for NVIDIA driver >= 560. Use open source kernel modules
  # on Turing or later GPUs (RTX series, GTX 16xx), closed source otherwise.
  # Kepler has no open variant at all.
  hardware.nvidia.open = false;

  # nvidia-drm is the only thing on this box that can register a DRM device.
  # It boots via legacy BIOS (grub on /dev/sda), so there is no EFI
  # framebuffer to fall back on -- no efifb, no simpledrm handoff, and the
  # nvidia module blacklists nouveau. With modeset=0 nvidia-drm loads, finds
  # it cannot set up KMS, and unloads itself per GPU:
  #
  #   Failed to initialize the nv-hotplug-helper DRM client
  #     (ensure DRM kernel mode setting is enabled via nvidia-drm.modeset=1)
  #   [drm] [nvidia-drm] [GPU ID 0x00000100] Unloading driver
  #
  # leaving no /dev/dri/card* at all. systemd-logind marks a seat graphical
  # only when it owns a master-of-seat DRM device, so seat0 came up
  # CanGraphical=no and lightdm then sits there forever without ever
  # launching an X server -- running, no children, nothing logged. Enabling
  # modesetting gives nvidia-drm.modeset=1, which keeps the DRM device
  # registered and makes the seat graphical.
  hardware.nvidia.modesetting.enable = true;

  system.stateVersion = "20.03";

}
