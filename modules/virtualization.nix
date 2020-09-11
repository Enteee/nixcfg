{ config, pkgs, lib, ... }:

with lib;

let

  configuration = config;

  #
  # Build a new vm from scratch
  mkNixOSVM = {
    config ? {},
    virtualisation ? {},
  }: let
    nixpkgs = import <nixpkgs/nixos> {
      configuration = config;
    };
  in nixpkgs.vm;

  #
  # Build a vm based on the current
  # configuration, overwritten with the
  # supplied config
  mkNixOSCloneVM = {
    config ? {},
    virtualisation ? {},
  }: let
    nixpkgs = (
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
    );
  in nixpkgs.vm;

  #
  # virtualisation options for graphical vms
  virtualisation = {

    graphical = {
      graphics = false;
      cores = 6;
      memorySize = 8192;
      diskSize = 5120;
      qemu = {
        options = [
          "-display spice-app"

          # spice
          "-device virtio-serial-pci"

          "-device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"
          "-chardev spicevmc,id=spicechannel0,name=vdagent"

          "-spice unix,addr=vm_spice.socket,disable-ticketing"
        ];
      };
    };
  };

  vmConfig-overrides = {
    home-manager.users.ente = {

      home.file.".background-image".source = ../users/backgrounds/raven-background-inverted.jpg;

      xsession = {

        windowManager.i3.config.modifier = "Mod1";

        initExtra = ''
          ${config.home-manager.users.ente.xsession.initExtra}
          ${pkgs.spice-vdagent}/bin/spice-vdagent
          '';
        };

    };

    services.qemuGuest.enable = true;
    services.spice-vdagentd.enable = true;
    services.xserver.videoDrivers = [ "qxl" ];

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
            config = vmConfig-overrides;
            virtualisation = virtualisation.graphical;
          }
        )

        (
          mkNixOSCloneVM {
            config = vmConfig-overrides // {
              networking.hostName = "hackthebox";
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
    environment.sessionVariables.SHARED_DIR = "\${HOME}/shared";

    home-manager.users.ente.xsession.initExtra = ''
      mkdir -p "''${SHARED_DIR}"
      '';
  };
}
