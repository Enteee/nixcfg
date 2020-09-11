{ config, pkgs, ... }:

let
  identity-file = toString ../keys/private/ente-duckpond.ch;
in {

  imports = [
    ../overlays
  ];

  environment.systemPackages = with pkgs; [
    sshfs
    keepass
  ];

  nixpkgs.overlays = [
    (
      self: super:
      {
        keepass = super.keepass.override {
          plugins = with pkgs; [ keepass-otpkeyprov ];
        };
      }
    )
  ];

  fileSystems."/mnt/keys" = {
    device = "ente@mail.duckpond.ch:/home/ente/keys";
    fsType = "sshfs";
    options = [
      "port=7410"
      ("IdentityFile=" + identity-file)
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=30"
      "_netdev"
      "users"
      "idmap=user"
      "ControlMaster=no"
      "allow_other"
      "reconnect"
    ];
  };

}
