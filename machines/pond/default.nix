{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/basesystem.nix
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Autodetect other systems
  boot.loader.grub.useOSProber = true;

  networking.hostName = "pond";

  services.xserver = {
    videoDrivers = [
      "nvidia"
    ];
  };

  # other options are: legacy_340 legacy_470 stable beta vulkan_beta
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

  # Required for NVIDIA driver >= 560. Use open source kernel modules
  # on Turing or later GPUs (RTX series, GTX 16xx), closed source otherwise.
  hardware.nvidia.open = false;

  system.stateVersion = "20.03";

}
