{ config, pkgs, lib, ... }:

with lib;

let

  configuration = config;

  mkVM = {nixpkgs}: let
    vm = nixpkgs.vm;
  in pkgs.stdenv.mkDerivation {
    name = "${vm.name}-wrapper";

    version = "0.1";
    phases = [ "installPhase" ];

    installPhase = ''
      mkdir -p $out/bin
      cp ${vm}/bin/* $out/bin

      for f in ${vm}/bin/run-*; do
        fBaseName="$(basename "$f" )"
        dstScript="$out/bin/$fBaseName-nonetwork"
        cat > "$dstScript" <<EOF
        #!${pkgs.runtimeShell}
        export QEMU_NET_OPTS="restrict=y"
        $f $@
      EOF
        chmod +x "$dstScript"
      done
    '';
  };


  #
  # Build a new vm from scratch
  mkNixOSVM = {
    config ? {},
    ...
  }: mkVM {
    nixpkgs = import <nixpkgs/nixos> {
      configuration = config;
    };
  };

  #
  # Build a vm based on the current
  # configuration, overwritten with the
  # supplied config
  mkNixOSCloneVM = {
    config ? {},
    virtualisation ? {},
  }: mkVM {
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
  };

  #
  # various virtualisation options
  virtualisation = {

    # graphical vms
    graphical = {

      # persist changes made to nix store
      writableStoreUseTmpfs = false;

      graphics = false;
      cores = 6;
      memorySize = 8192;
      diskSize = 10240;
      qemu = {
        options = [
          # always try to emulate host cpu
          "-cpu host"

          # use Spice app for display
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

    #boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
    boot.extraModprobeConfig = ''
      options kvm ignore_msrs=1
      options kvm_intel nested=1 ept=1
    '';

    # Add VMS
    /*
    environment.systemPackages = if ( config.virtualisation.recursionDepth == 0 )
      then [
        (
          mkNixOSCloneVM {
            config = vmConfig-overrides;
            virtualisation = virtualisation.graphical;
          }
        )

      ] else [];
    */

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

    #
    # VirtualBox
    #
    #virtualisation.virtualbox.host.enable = true;
    #users.extraGroups.vboxusers.members = [ "ente" ];
    #virtualisation.virtualbox.host.enableExtensionPack = true;

    #
    # VMware
    #
    #virtualisation.vmware.host.enable = true;
  };
}
