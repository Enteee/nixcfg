{ pkgs, ... }:

# Nix daemon, store housekeeping and evaluation policy.

{
  environment.systemPackages = [ pkgs.nix-index ];

  nixpkgs.config.allowUnfree = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # No channels. The system builds from flake.lock, and because this is a
  # flake-built system nixpkgs.flake.setNixPath/setFlakeRegistry already point
  # <nixpkgs> and `nix build nixpkgs#...` at the flake's own locked nixpkgs --
  # so nix-shell and friends keep working. The root channels were stale
  # duplicates of the flake inputs that nothing read.
  #
  # This removes the nix-channel command and leaves NIX_PATH as just
  # nixpkgs=flake:nixpkgs. It does not delete the channel state: activation
  # warns while /nix/var/nix/profiles/per-user/root/channels and the
  # ~/.nix-defexpr/channels symlinks still exist, because nix#9574 means a
  # leftover channels directory is consulted anyway when NIX_PATH is unset.
  nix.channel.enable = false;

  # Set trusted users (for cachix)
  nix.settings.trusted-users = [ "root" "ente" ];

  # Collect garbage on a schedule, so it has a bounded lifetime. Without this
  # nothing in the store is ever freed: building NixOS VM tests (the Loom
  # appliance suite) leaves a full system closure behind per iteration, and they
  # accumulate until the disk is full.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # ...and collect on demand as well, which is what keeps a long build from
  # dying at 100% disk halfway through: the daemon frees garbage whenever free
  # space drops below min-free, until max-free is reached.
  #
  # Deliberately not moving the build directory to /tmp to go with it. That is a
  # tmpfs (boot.tmp.useTmpfs in basesystem.nix), and a VM test's disk images --
  # 4 to 8 GB of qcow2 -- belong on a disk, not in RAM.
  nix.settings.min-free = 25 * 1024 * 1024 * 1024;
  nix.settings.max-free = 100 * 1024 * 1024 * 1024;

  # Hardlink identical files in the store. Repeated builds of one thing differ
  # in a handful of files and duplicate the rest, so this is worth a lot on a
  # store that carries several appliance images.
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  # Build aarch64 derivations locally. Registers qemu-user with binfmt_misc so
  # foreign-arch binaries run transparently during the build.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
