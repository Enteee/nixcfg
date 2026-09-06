{ config, pkgs, ... }:

{
  boot.extraModprobeConfig = ''
    options kvm ignore_msrs=1
    options kvm_intel nested=1 ept=1
  '';

  virtualisation = {
    libvirtd.enable = true;

    # allow usb redirection using spice
    spiceUSBRedirection.enable = true;
  };

  # allow ip forwarding for vms
  boot.kernel.sysctl = { "net.ipv4.ip_forward" = 1; };
  networking.firewall.checkReversePath = false;

  environment.sessionVariables.LIBVIRT_DEFAULT_URI = "qemu:///system";
  environment.sessionVariables.SHARED_DIR = "\${HOME}/shared";

  home-manager.users.ente.xsession.initExtra = ''
    mkdir -p "''${SHARED_DIR}"
    '';
}
