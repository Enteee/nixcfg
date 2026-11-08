{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix

    ../../modules/basesystem.nix
    ../../modules/nix.nix
    ../../modules/desktop.nix
    ../../modules/gaming.nix

    ../../modules/nosuspend.nix
    ../../modules/wd-idle3.nix
    ../../modules/vibewars-runners.nix
  ];

  boot.loader.systemd-boot = {
    enable = true;
    # The ESP is 1G. Unbounded, systemd-boot keeps a kernel and initrd per
    # generation until it fills and the next switch fails.
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Root's LUKS container, opened in the initrd. Addressed by GPT partition
  # label rather than UUID, which is what let this config be written before the
  # disk it describes existed: the LUKS UUID only appears after luksFormat, and
  # a generated .nix file would be untracked and so invisible to the flake.
  # by-partlabel and by-uuid come from the same udev rules file (systemd's
  # 60-persistent-storage.rules), and puddle boots a LUKS root from by-uuid, so
  # those rules demonstrably run in the initrd.
  # Unlocked from a keyfile baked into the initrd, so the machine boots -- and
  # resumes from hibernation -- with nobody present. This is what makes the
  # scheduled rtcwake useful.
  #
  # Be clear about what this costs: the initrd lives on /boot, which is a plain
  # vfat ESP, so the key sits unencrypted next to the thing it unlocks. Against
  # someone who takes this SSD, root is no longer protected, and because
  # /home's keyfile lives on root (see environment.etc.crypttab below), neither
  # is /home. This is equivalent to not encrypting root at all -- it is just
  # reversible in two lines rather than by a full reencrypt.
  #
  # The one protection that survives: the keys are on the SSD, not on the array,
  # so RMA'ing or discarding a failed WD array drive still leaks nothing.
  #
  # There is no better option on this box -- no TPM, so nothing can seal a key
  # to the hardware (verified: /sys/class/tpm is empty).
  #
  # The interactive passphrase stays in its own keyslot as a fallback, so a
  # corrupted ESP does not lock you out.
  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-partlabel/cryptroot";
    allowDiscards = true;
    keyFile = "/root-keyfile.bin";
  };

  # Appended to the initrd at bootloader-install time. Note that
  # `nixos-rebuild switch` regenerates initrds for *past* generations too, so if
  # this file is ever moved or deleted, the generations referencing it have to be
  # garbage collected as well.
  boot.initrd.secrets."/root-keyfile.bin" = "/etc/luks-keys/root";

  # Hibernation. The swap LV shares root's LUKS container, so it is encrypted
  # with no second passphrase prompt.
  boot.resumeDevice = "/dev/vg-pond/swap";

  networking.hostName = "pond";

  # ---------------------------------------------------------------------------
  # Tuning for the CI/agent role. Measured, not guessed: with the desktop idle
  # this box sits at 10 GiB of 15 GiB used with 371 MiB already swapped, so it
  # is RAM-bound well before it is disk-bound. For reference, the runner scratch
  # on the md array does 1388 small-file creates/s and 50 MB/s sequential,
  # against 7607/s and 715 MB/s for tmpfs -- real, but a 5x gap matters far less
  # than swapping.
  # ---------------------------------------------------------------------------

  # Four concurrent derivations rather than eight. With cores = 2 (see
  # modules/nix.nix) that is exactly the 8 threads this CPU has, and it halves
  # peak build memory, which is the binding constraint. Overrides the
  # mkDefault 8 that nixos-generate-config wrote.
  nix.settings.max-jobs = 4;

  # Compressed swap in RAM, taken before the disk swap (zram defaults to
  # priority 5, the swap LV is -2). Evicting an idle agent into zstd-compressed
  # RAM costs microseconds; evicting it onto a 2012 SandForce SSD costs
  # milliseconds and wears the flash. 25% of 15 GiB, so ~3.8 GiB of zram
  # holding perhaps 8-10 GiB of actual pages.
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # Deliberately raised, not lowered.
  #
  # The instinct on a machine that swaps to a slow SSD is to discourage swapping
  # (swappiness 10). With zram in front of that SSD the calculus inverts: swap
  # is now cheap for the first few GiB, and being reluctant to use it just
  # leaves anonymous pages pinned while the page cache and builds fight over
  # what is left. 100 is the usual recommendation for a zram-fronted system.
  #
  # If zram is ever removed, put this back to 10 or drop the line -- the two
  # settings only make sense as a pair.
  boot.kernel.sysctl."vm.swappiness" = 100;

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

  # nvidia-drm has to keep KMS, or this machine has no graphical seat at all.
  #
  # The nvidia module blacklists nouveau, so nvidia-drm is the only driver here
  # that can register a DRM device. With modeset=0 it loads, finds it cannot set
  # up KMS, and unloads itself again:
  #
  #   Failed to initialize the nv-hotplug-helper DRM client
  #     (ensure DRM kernel mode setting is enabled via nvidia-drm.modeset=1)
  #   [drm] [nvidia-drm] [GPU ID 0x00000100] Unloading driver
  #
  # leaving no /dev/dri/card* at all. systemd-logind marks a seat graphical only
  # when it owns a master-of-seat DRM device, so seat0 came up CanGraphical=no
  # and lightdm sat there forever without ever launching an X server -- running,
  # no children, nothing logged.
  #
  # This was originally diagnosed while pond booted legacy BIOS, where there is
  # no EFI framebuffer to fall back on: no efifb, no simpledrm handoff, so
  # nothing else could provide a DRM device. Under UEFI there would be a
  # framebuffer, but relying on it would mean X on simpledrm rather than on the
  # nvidia driver, so modesetting stays on either way.
  hardware.nvidia.modesetting.enable = true;

  system.stateVersion = "20.03";

}
