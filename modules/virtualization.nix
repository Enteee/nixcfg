{ config, pkgs, ... }:

let
in {

  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];

  virtualisation = {
    libvirtd.enable = true;

    # Define virtualization options
    # currently disabled and replaced
    # with environment variable QEMU_OPTS

    #cores = 5;
    #memorySize = 4096;
    #qemu.options = [
    #  "-vga virtio"
    #];
  };
  environment.variables = {
    QEMU_OPTS = "-m 4096 -smp 4 -enable-kvm";
  };


  # allow ip forwarding for vms
  boot.kernel.sysctl = { "net.ipv4.ip_forward" = 1; };
  networking.firewall.checkReversePath = false;

}
