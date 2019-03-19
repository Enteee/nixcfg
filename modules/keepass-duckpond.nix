{ config, pkgs, ... }:

let
  IdentityFile= toString ../keys/private/ente-duckpond.ch;
in {

  imports = [
    ../overlays
  ];

  environment.systemPackages = with pkgs; [
    pkgs.sshfs
    pkgs.keepass
  ];

  nixpkgs.overlays = [
    ( 
      self: super:
      {
        keepass = super.keepass.override {
          plugins = [ pkgs.mine.keepass-keepassotpkeyprov ];
        };
      }
    )
  ];

  fileSystems."/mnt/keys" = { 
    device = "ente@duckpond.ch:/home/ente/keys";
    fsType = "sshfs";
    options = [
      "port=7410"
      ("IdentityFile=" + IdentityFile)
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