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
    device = "ente@duckpond.ch:/home/ente/duckpond.ch/_env/host-data/keys";
    fsType = "sshfs";
    options = [
      ("IdentityFile=" + identity-file)
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=30"
      "_netdev"
      # User option broken, but should work anyways:
      # https://github.com/karelzak/util-linux/issues/1193
      #"users"
      "idmap=user"
      "ControlMaster=no"
      "allow_other"
      "reconnect"
    ];
  };

}
