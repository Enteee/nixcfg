{ lib, ... }:

# The post-rebuild boot and root layout for pond: UEFI + systemd-boot, LUKS
# root, LVM. Kept as an overlay module exposed through the `pond-uefi` flake
# output rather than folded into ./default.nix, because the devices below do
# not exist until the rebuild has happened -- merging it early would leave the
# running pond unable to `nixos-rebuild switch` in the meantime.
#
# Once pond has booted this way and hibernation is confirmed, fold these into
# ./default.nix and ./hardware-configuration.nix and delete both this file and
# the pond-uefi output.
#
# Driven by ./install-uefi.sh from a UEFI-booted installer. Two things were
# staged onto /home beforehand, because /nix and / are on the disk that gets
# wiped:
#
#   /home/pond-state.tar.gz  the state that cannot be rebuilt -- the /home LUKS
#                            keyfile and header backup, /etc/shadow, and
#                            /var/lib/nixos/uid-map (syncthing is uid 237 and
#                            owns 76G under /home/syncthing)
#   /home/nix-cache/         a file:// binary cache holding this closure, so the
#                            installer copies ~21 GiB locally instead of
#                            re-downloading it and rebuilding nvidia 470
#
# Everything is addressed by GPT partition label, set by `sgdisk -c` in the
# install script. That is deliberate: the LUKS UUID only exists after
# luksFormat, so a by-uuid config could not be written ahead of time, and a
# generated .nix file would be untracked and therefore invisible to the flake.
# by-partlabel and by-uuid are created by the same udev rules file
# (systemd's 60-persistent-storage.rules, lines 146 and 138), and puddle
# already boots a LUKS root from by-uuid -- so those rules demonstrably run in
# the initrd.

{
  boot.loader.grub.enable = lib.mkForce false;

  boot.loader.systemd-boot = {
    enable = true;
    # The ESP is 1G. Unbounded, systemd-boot keeps a kernel and initrd per
    # generation until it fills and the next switch fails.
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-partlabel/cryptroot";
    allowDiscards = true;
  };

  # Hibernation. The swap LV lives inside the same LUKS container as root, so
  # it is encrypted without a second passphrase prompt.
  boot.resumeDevice = "/dev/vg-pond/swap";

  fileSystems."/" = {
    device = lib.mkForce "/dev/vg-pond/root";
    fsType = lib.mkForce "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/ESP";
    fsType = "vfat";
    # The ESP holds unencrypted kernels and initrds; keep it root-only.
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = lib.mkForce [ { device = "/dev/vg-pond/swap"; } ];
}
