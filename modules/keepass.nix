{ config, ... }:

{
  fileSystems."/mnt/keys" = { 
      device = "ente@duckpond.ch:/home/ente/keys";
      fsType = "sshfs";
      options = [
        "port=7410"
        "IdentityFile=/home/ente/.ssh/id_rsa"
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
