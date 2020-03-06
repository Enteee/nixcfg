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
              networking.hostName = "puddleVM2";

              home-manager.users.ente.home.file.".background-image".source = ../users/backgrounds/raven-background-inverted.jpg;

              services.xserver.resolutions = [
                { x = 1920; y = 1080; }
              ];
            };

            virtualisation = {
              cores = 6;
              memorySize = 4096;
              qemu = {
                options = [
                  "-vga virtio"
                  "-display sdl,gl=on"
                ];
              };
            };

          }
        )
      ] else [];

    virtualisation = {
      libvirtd.enable = true;
    };

    # allow ip forwarding for vms
    boot.kernel.sysctl = { "net.ipv4.ip_forward" = 1; };
    networking.firewall.checkReversePath = false;
  };
}
