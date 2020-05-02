{ ... }:

let
  hackthebox-config = toString ../keys/private/ente-duckpond.ch;

in {
  services.openvpn.servers = {
    hackthebox = {
      autoStart = false;
      config = '' config ${hackthebox-config} '';
    };
  };

}
