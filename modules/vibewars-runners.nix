{ ... }:

# Disk cap for VibeWars' company CI runners (ADR-0045): the runner supervisor
# starts no runner unless its scratch dir is a filesystem of its own, so a
# runaway job fills this image and not /home.
#
# The image itself is made once by hand; NixOS only mounts it. Preallocated,
# not sparse: the cap is real, and a full /home cannot make the image fail to
# grow underneath a job.
#
#   sudo fallocate -l 128G /home/vibewars-runners.img
#   sudo chmod 600 /home/vibewars-runners.img
#   sudo mkfs.ext4 -m 0 -E nodiscard -L vibewars-runners /home/vibewars-runners.img
#
# `-E nodiscard` is load-bearing and easy to miss. mke2fs discards by default,
# and on a file-backed target "discard" means hole-punching -- so a plain
# mkfs.ext4 silently undoes the fallocate and leaves a sparse image. Check with
# `stat -c %b` (want 268435456 512-byte blocks, not ~2M) rather than trusting
# the apparent size, which looks right either way.
#
# -m 0 drops ext4's 5% root reserve, which would be wasted here. 128G allows
# 4 runners about 32G each, each with its own fresh /nix; it cannot easily be
# shrunk later. The image sits outside /home/ente so it stays out of backups
# and out of home-manager's view.
#
# After the first rebuild the mountpoint belongs to root, so once:
#
#   sudo chown ente:users ~/.local/state/vibewars/runners
#   chmod 700 ~/.local/state/vibewars/runners
#
# That ownership lives inside the image, so it survives reboots.
#
# On /home rather than / because / has ~26G free. That is the 5400rpm md
# array -- slower CI than the SSD would give, but encrypted at rest.
{
  fileSystems."/home/ente/.local/state/vibewars/runners" = {
    device = "/home/vibewars-runners.img";
    fsType = "ext4";
    options = [
      "loop"
      "noatime"
      # The image lives on /home, which waits for crypthome.
      "x-systemd.requires-mounts-for=/home"
      # A missing or broken image must not stop pond from booting:
      # runners just stay off, and the supervisor says why.
      "nofail"
    ];
  };
}
