{ config, pkgs, ... }:

let
in {

  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
  virtualisation.libvirtd.enable = true;

  # allow ip forwarding for vms
  boot.kernel.sysctl = { "net.ipv4.ip_forward" = 1; };
  networking.firewall.checkReversePath = false;

}
