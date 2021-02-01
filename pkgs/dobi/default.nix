{ lib, stdenv, buildEnv, fetchurl }:

with lib;
let
  version = "0.14.0";
in stdenv.mkDerivation {

  pname = "dobi";
  inherit version;

  src = fetchurl {
    url = "https://github.com/dnephin/dobi/releases/download/v${version}/dobi-Linux";
    sha256 = "18q5lxk52j2c8chhprachpbfz5gy9704vk5i67dcg94wim2i7m8d";
  };

  meta = {
    description = "A build automation tool for Docker applications";
    homepage    = "https://dnephin.github.io/dobi/";
    platforms   = platforms.linux;
    license     = licenses.asl20;
    maintainers = [ maintainers.ente ];
  };

  phases = ["installPhase" "patchPhase"];

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/dobi
    chmod +x $out/bin/dobi
  '';
}
