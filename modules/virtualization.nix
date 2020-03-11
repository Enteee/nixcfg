{ config, pkgs, lib, ... }:

with lib;

let

  configuration = config;

  mkNixOSVM = {
    config ? {},
    virtualisation ? {},
  }: (
    import <nixpkgs/nixos> {
      configuration = config;
    }
  ).vm;

  mkNixOSCloneVM = {
    config ? {},
    virtualisation ? {},
  }: (
    import <nixpkgs/nixos> {
      configuration = {
        imports = [
          (import <nixpkgs/nixos/lib/from-env.nix> "NIXOS_CONFIG" <nixos-config>) {
            config = mapAttrsRecursive (path: value: (mkVMOverride value) ) config // {
                virtualisation.recursionDepth = configuration.virtualisation.recursionDepth + 1;
            };
          }
        ];

        inherit virtualisation;
      };
    }
  ).vm;

  virtualisation = {

    # virtualisation options for graphical vms
    graphical = {
      cores = 6;
      memorySize = 4096;
      qemu = {
        options = [
          "-vga virtio"
          "-display sdl,gl=on"
        ];
      };
    };
  };

in {

  options.virtualisation = {

    recursionDepth = mkOption {
      type = types.int;
      default = 0;
    };

  };

  config = {

    boot.kernelModules = [ "kvm-intel" "kvm-amd" ];

    # Add VMS
    environment.systemPackages = if ( config.virtualisation.recursionDepth == 0 )
      then [
        (
          mkNixOSCloneVM {
            config = {
              home-manager.users.ente = {
                home.file.".background-image".source = ../users/backgrounds/raven-background-inverted.jpg;
                xsession.windowManager.i3.config.modifier = "Mod1";

                services.redshift.enable = false;
              };

              services.qemuGuest.enable = true;

              services.xserver.resolutions = [
                { x = 2560; y = 1440; }
              ];
            };
            virtualisation = virtualisation.graphical;
          }
        )

        (
          mkNixOSCloneVM {
            config = {

              networking.hostName = "hackthebox";

              home-manager.users.ente = {
                home.file.".background-image".source = ../users/backgrounds/raven-background-inverted.jpg;
                xsession.windowManager.i3.config.modifier = "Mod1";

                services.redshift.enable = false;
              };

              services.qemuGuest.enable = true;
              services.spice-vdagentd.enable = true;

              services.xserver.resolutions = [
                { x = 2560; y = 1440; }
              ];

              services.openvpn.servers.hackthebox.autoStart = true;
            };
            virtualisation = virtualisation.graphical;
          }
        )
      ] else [];

    virtualisation = {
      libvirtd = {
        enable = true;
      };
    };

    # allow ip forwarding for vms
    boot.kernel.sysctl = { "net.ipv4.ip_forward" = 1; };
    networking.firewall.checkReversePath = false;

    environment.sessionVariables.LIBVIRT_DEFAULT_URI = "qemu:///system";
  };
}
