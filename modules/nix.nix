{ pkgs, ... }:

# Nix daemon, store housekeeping and evaluation policy.

{
  environment.systemPackages = [ pkgs.nix-index ];

  nixpkgs.config.allowUnfree = true;

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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
  nix.settings.trusted-users = [
    "root"
    "ente"
  ];

  # Cap per-derivation parallelism. `cores` defaults to 0, which means "use
  # every thread on the machine" -- so it multiplies with max-jobs rather than
  # dividing. On pond that was 8 jobs x 8 threads = up to 64-way oversubscription
  # on an 8-thread CPU.
  nix.settings.cores = 2;

  # Keep Nix's build scratch off tmpfs. boot.tmp.useTmpfs puts /tmp in RAM, so
  # with build-dir unset every derivation unpacks into memory and competes for
  # it with the processes the build exists to serve. That is tolerable on a
  # desktop and actively harmful on a host running CI.
  #
  # A dedicated directory rather than /var/tmp: Nix validates build-dir at build
  # time and refuses anything world-writable or a symlink --
  #
  #   error: Path "/var/tmp" is world-writable or a symlink.
  #          That's not allowed for security.
  #
  # -- and /var/tmp is 1777 like /tmp. Note the setting is still *accepted* into
  # nix.conf, so `nix config show` looks correct and only an actual build fails.
  #
  # This also supersedes the reasoning in the min-free comment below, which
  # argued against moving builds *to* /tmp -- they were already there.
  nix.settings.build-dir = "/var/lib/nix-build";
  systemd.tmpfiles.rules = [
    "d /var/lib/nix-build 0755 root root -"
  ];

  # devenv's projects pin `github:cachix/devenv-nixpkgs/rolling` rather than
  # upstream nixpkgs, and that fork is not on cache.nixos.org -- so without this
  # every devenv dependency gets built locally. extra-* rather than plain
  # substituters, which would replace cache.nixos.org instead of adding to it.
  #
  # The key was fetched from the cache's own API, not recalled:
  #   curl https://devenv.cachix.org/api/v1/cache/devenv
  nix.settings.extra-substituters = [ "https://devenv.cachix.org" ];
  nix.settings.extra-trusted-public-keys = [
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
  ];

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
